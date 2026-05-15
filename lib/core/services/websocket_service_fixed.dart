import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_client.dart';

enum WebSocketConnectionStatus { disconnected, connecting, connected, reconnecting, error }

class WebSocketEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final StreamController<WebSocketEvent> _eventController = 
      StreamController<WebSocketEvent>.broadcast();
  
  final StreamController<WebSocketConnectionStatus> _connectionController = 
      StreamController<WebSocketConnectionStatus>.broadcast();
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Streams
  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<WebSocketConnectionStatus> get connectionStatus => _connectionController.stream;
  
  WebSocketConnectionStatus _currentStatus = WebSocketConnectionStatus.disconnected;
  WebSocketConnectionStatus get currentStatus => _currentStatus;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _updateConnectionStatus(WebSocketConnectionStatus.connecting);
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final dio = await ApiClient.create();
      final baseUrl = dio.options.baseUrl;

      _socket = IO.io(
        baseUrl.replaceFirst('http', 'ws'),
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({
            'token': token,
          })
          .build(),
      );

      _setupEventListeners();
      
    } catch (e) {
      _updateConnectionStatus(WebSocketConnectionStatus.error);
      _handleConnectionError(e.toString());
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _updateConnectionStatus(WebSocketConnectionStatus.connected);
      _reconnectAttempts = 0;
      debugPrint('WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
      debugPrint('WebSocket disconnected');
      _scheduleReconnect();
    });

    _socket!.onConnectError((error) {
      _updateConnectionStatus(WebSocketConnectionStatus.error);
      debugPrint('WebSocket connection error: $error');
      _handleConnectionError(error.toString());
    });

    _socket!.onError((error) {
      debugPrint('WebSocket error: $error');
      _handleConnectionError(error.toString());
    });

    // Custom event listeners
    _socket!.on('new_message', (data) {
      _handleIncomingEvent('new_message', data as Map<String, dynamic>);
    });

    _socket!.on('new_notification', (data) {
      _handleIncomingEvent('new_notification', data as Map<String, dynamic>);
    });

    _socket!.on('booking_update', (data) {
      _handleIncomingEvent('booking_update', data as Map<String, dynamic>);
    });

    _socket!.on('quote_update', (data) {
      _handleIncomingEvent('quote_update', data as Map<String, dynamic>);
    });

    _socket!.on('dispute_update', (data) {
      _handleIncomingEvent('dispute_update', data as Map<String, dynamic>);
    });

    _socket!.on('payment_update', (data) {
      _handleIncomingEvent('payment_update', data as Map<String, dynamic>);
    });

    _socket!.on('user_status_update', (data) {
      _handleIncomingEvent('user_status_update', data as Map<String, dynamic>);
    });
  }

  void _handleIncomingEvent(String type, Map<String, dynamic> data) {
    final event = WebSocketEvent(type: type, data: data);
    _eventController.add(event);
    debugPrint('Received WebSocket event: $type');
  }

  void _updateConnectionStatus(WebSocketConnectionStatus status) {
    _currentStatus = status;
    _connectionController.add(status);
  }

  void _handleConnectionError(String error) {
    debugPrint('WebSocket connection error: $error');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      _updateConnectionStatus(WebSocketConnectionStatus.reconnecting);
      debugPrint('Attempting to reconnect... Attempt $_reconnectAttempts');
      connect();
    });
  }

  void sendMessage(String event, Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
      debugPrint('Sent WebSocket event: $event');
    } else {
      debugPrint('Cannot send message - WebSocket not connected');
    }
  }

  void joinRoom(String roomId) {
    sendMessage('join_room', {'room': roomId});
  }

  void leaveRoom(String roomId) {
    sendMessage('leave_room', {'room': roomId});
  }

  void subscribeToUserUpdates(String userId) {
    sendMessage('subscribe_user', {'user_id': userId});
  }

  void unsubscribeFromUserUpdates(String userId) {
    sendMessage('unsubscribe_user', {'user_id': userId});
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
