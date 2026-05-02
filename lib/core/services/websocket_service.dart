import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
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

  WebSocketChannel? _channel;
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
    if (_channel != null) {
      return;
    }

    _updateConnectionStatus(WebSocketConnectionStatus.connecting);
    
    try {
      final token = await _storage.read(key: 'auth_token');
      final dio = await ApiClient.create();
      final baseUrl = dio.options.baseUrl;
      
      // Determine WebSocket endpoint
      String wsUrl;
      if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
        // Local development
        wsUrl = 'ws://localhost:5000/ws';
      } else {
        // Deployed environment
        wsUrl = baseUrl.replaceFirst('http', 'ws') + '/ws';
      }
      
      // Add JWT token as query parameter
      final wsUrlWithToken = token != null 
          ? '$wsUrl?token=$token'
          : wsUrl;

      _channel = WebSocketChannel.connect(Uri.parse(wsUrlWithToken));
      _setupEventListeners();
      
    } catch (e) {
      _updateConnectionStatus(WebSocketConnectionStatus.error);
      _handleConnectionError(e.toString());
    }
  }

  void _setupEventListeners() {
    if (_channel == null) return;

    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _handleWebSocketMessage(data);
          _updateConnectionStatus(WebSocketConnectionStatus.connected);
          _reconnectAttempts = 0;
        } catch (e) {
          debugPrint('Error parsing WebSocket message: $e');
        }
      },
      onDone: () {
        _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
        debugPrint('WebSocket disconnected');
        _scheduleReconnect();
      },
      onError: (error) {
        _updateConnectionStatus(WebSocketConnectionStatus.error);
        debugPrint('WebSocket error: $error');
        _handleConnectionError(error.toString());
      },
    );
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final eventData = data['data'] as Map<String, dynamic>?;
    
    if (type != null && eventData != null) {
      switch (type) {
        case 'connection.ready':
          _handleConnectionReady(eventData);
          break;
        case 'message.created':
          _handleIncomingEvent('message.created', eventData);
          break;
        case 'message.updated':
          _handleIncomingEvent('message.updated', eventData);
          break;
        case 'message.read':
          _handleIncomingEvent('message.read', eventData);
          break;
        case 'notification.created':
          _handleIncomingEvent('notification.created', eventData);
          break;
        case 'location.share.started':
          _handleIncomingEvent('location.share.started', eventData);
          break;
        case 'location.share.stopped':
          _handleIncomingEvent('location.share.stopped', eventData);
          break;
        case 'location.point.received':
          _handleIncomingEvent('location.point.received', eventData);
          break;
        case 'pong':
          _handlePongResponse(eventData);
          break;
      }
    }
  }

  void _handleIncomingEvent(String type, Map<String, dynamic> data) {
    final event = WebSocketEvent(type: type, data: data);
    _eventController.add(event);
    debugPrint('Received WebSocket event: $type');
  }

  void _handleConnectionReady(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    if (userId != null) {
      debugPrint('WebSocket connection ready for user: $userId');
      _updateConnectionStatus(WebSocketConnectionStatus.connected);
      _reconnectAttempts = 0;
      
      // Emit connection ready event for providers to handle
      final event = WebSocketEvent(
        type: 'connection.ready',
        data: {'userId': userId},
      );
      _eventController.add(event);
    }
  }

  void _handlePongResponse(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as String?;
    debugPrint('Received pong response at: ${timestamp ?? 'unknown time'}');
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
    if (_channel != null) {
      final message = {
        'type': event,
        'data': data,
      };
      _channel!.sink.add(jsonEncode(message));
      debugPrint('Sent WebSocket event: $event');
    } else {
      debugPrint('Cannot send message - WebSocket not connected');
    }
  }

  void ping() {
    sendMessage('ping', {});
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
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _updateConnectionStatus(WebSocketConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
