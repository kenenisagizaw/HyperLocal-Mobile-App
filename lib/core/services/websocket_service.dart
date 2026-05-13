import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../data/datasources/local/local_storage.dart';
import '../constants/api_constants.dart';

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketEvent {
  WebSocketEvent({
    required this.type,
    required this.data,
    String? serverEvent,
    DateTime? timestamp,
  })  : serverEvent = serverEvent ?? type,
        timestamp = timestamp ?? DateTime.now();

  final String type;
  final String serverEvent;
  final Map<String, dynamic> data;
  final DateTime timestamp;
}

class WebSocketService {
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  static final WebSocketService _instance = WebSocketService._internal();

  final LocalStorage _storage = LocalStorage();
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  final StreamController<WebSocketConnectionStatus> _connectionController =
      StreamController<WebSocketConnectionStatus>.broadcast();

  io.Socket? _socket;
  Future<void>? _connectFuture;
  bool _intentionalDisconnect = false;
  WebSocketConnectionStatus _currentStatus =
      WebSocketConnectionStatus.disconnected;

  static const Map<String, String> _serverEvents = {
    'new_message': 'new_message',
    'chat.message': 'new_message',
    'message.created': 'new_message',
    'message.updated': 'message_updated',
    'message.read': 'message_read',
    'new_notification': 'new_notification',
    'notification.created': 'new_notification',
    'notification.read': 'notification_read',
    'notification.read_all': 'notifications_read_all',
    'booking_update': 'booking_update',
    'booking.updated': 'booking_update',
    'quote_update': 'quote_update',
    'quote.updated': 'quote_update',
    'dispute_update': 'dispute_update',
    'dispute.updated': 'dispute_update',
    'payment_update': 'payment_update',
    'payment.updated': 'payment_update',
    'user_status_update': 'user_status_update',
    'user.status.updated': 'user_status_update',
    'location.share.started': 'location_share_started',
    'location.share.stopped': 'location_share_stopped',
    'location.point.received': 'location_point_received',
  };

  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<WebSocketConnectionStatus> get connectionStatus =>
      _connectionController.stream;
  WebSocketConnectionStatus get currentStatus => _currentStatus;
  bool get isConnected => _socket?.connected ?? false;
  bool get isConnecting =>
      _currentStatus == WebSocketConnectionStatus.connecting ||
      _currentStatus == WebSocketConnectionStatus.reconnecting;

  Future<void> connect() async {
    if (isConnected) return;
    if (_connectFuture != null) return _connectFuture;

    _connectFuture = _connect();
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connect() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
      debugPrint('Socket.IO connect skipped: missing access token');
      return;
    }

    _intentionalDisconnect = false;
    _updateConnectionStatus(
      _socket == null
          ? WebSocketConnectionStatus.connecting
          : WebSocketConnectionStatus.reconnecting,
    );

    final socket = _socket ?? _createSocket(token);
    _socket = socket;
    socket.auth = {'token': token};

    if (!socket.connected) {
      debugPrint('Socket.IO connecting');
      socket.connect();
    }
  }

  io.Socket _createSocket(String token) {
    final socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      _updateConnectionStatus(WebSocketConnectionStatus.connected);
      debugPrint('Socket.IO connected: ${socket.id}');
    });

    socket.onDisconnect((_) {
      _updateConnectionStatus(
        _intentionalDisconnect
            ? WebSocketConnectionStatus.disconnected
            : WebSocketConnectionStatus.reconnecting,
      );
      debugPrint('Socket.IO disconnected');
    });

    socket.onReconnectAttempt((_) async {
      final refreshedToken = await _storage.getAccessToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        socket.auth = {'token': refreshedToken};
      }
      _updateConnectionStatus(WebSocketConnectionStatus.reconnecting);
    });

    socket.onReconnect((_) {
      _updateConnectionStatus(WebSocketConnectionStatus.connected);
    });

    socket.onConnectError((error) {
      _updateConnectionStatus(WebSocketConnectionStatus.error);
      debugPrint('Socket.IO connect error: $error');
    });

    socket.onError((error) {
      _updateConnectionStatus(WebSocketConnectionStatus.error);
      debugPrint('Socket.IO error: $error');
    });

    for (final eventName in _serverEvents.keys) {
      socket.on(eventName, (payload) => _handleIncomingEvent(eventName, payload));
    }

    return socket;
  }

  void _handleIncomingEvent(String type, dynamic payload) {
    final data = _normalizePayload(payload);
    final internalType = _serverEvents[type] ?? type;
    debugPrint('Socket.IO event received: $type -> $internalType');
    _eventController.add(
      WebSocketEvent(type: internalType, serverEvent: type, data: data),
    );
  }

  Map<String, dynamic> _normalizePayload(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return payload.cast<String, dynamic>();
    return {'value': payload};
  }

  void emit(String event, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      debugPrint('Cannot emit $event: socket is not connected');
      return;
    }
    socket.emit(event, data);
  }

  void joinRoom(String roomId) => emit('room.join', {'roomId': roomId});
  void leaveRoom(String roomId) => emit('room.leave', {'roomId': roomId});
  void subscribeToUserUpdates(String userId) =>
      emit('user.subscribe', {'userId': userId});
  void unsubscribeFromUserUpdates(String userId) =>
      emit('user.unsubscribe', {'userId': userId});

  void disconnect() {
    _intentionalDisconnect = true;
    final socket = _socket;
    if (socket != null) {
      for (final eventName in _serverEvents.keys) {
        socket.off(eventName);
      }
      socket.dispose();
      _socket = null;
    }
    _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
  }

  Future<void> reconnectIfNeeded() async {
    if (_intentionalDisconnect || isConnected || isConnecting) return;
    await connect();
  }

  void resetSession() {
    disconnect();
  }

  void _updateConnectionStatus(WebSocketConnectionStatus status) {
    _currentStatus = status;
    if (!_connectionController.isClosed) {
      _connectionController.add(status);
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
