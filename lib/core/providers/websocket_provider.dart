import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  
  WebSocketConnectionStatus _connectionStatus = WebSocketConnectionStatus.disconnected;
  WebSocketConnectionStatus get connectionStatus => _connectionStatus;
  
  bool get isConnected => _connectionStatus == WebSocketConnectionStatus.connected;
  bool get isConnecting => _connectionStatus == WebSocketConnectionStatus.connecting;
  bool get isReconnecting => _connectionStatus == WebSocketConnectionStatus.reconnecting;
  bool get hasError => _connectionStatus == WebSocketConnectionStatus.error;
  
  String? _lastError;
  String? get lastError => _lastError;
  
  WebSocketProvider() {
    _initialize();
  }
  
  void _initialize() {
    // Listen to connection status changes
    _webSocketService.connectionStatus.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });
    
    // Listen to WebSocket events
    _webSocketService.events.listen((event) {
      _handleWebSocketEvent(event);
    });
  }
  
  Future<void> connect() async {
    try {
      await _webSocketService.connect();
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }
  
  void disconnect() {
    _webSocketService.disconnect();
  }
  
  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'new_message':
        _handleNewMessage(event.data);
        break;
      case 'new_notification':
        _handleNewNotification(event.data);
        break;
      case 'booking_update':
        _handleBookingUpdate(event.data);
        break;
      case 'quote_update':
        _handleQuoteUpdate(event.data);
        break;
      case 'dispute_update':
        _handleDisputeUpdate(event.data);
        break;
      case 'payment_update':
        _handlePaymentUpdate(event.data);
        break;
      case 'user_status_update':
        _handleUserStatusUpdate(event.data);
        break;
      default:
        debugPrint('Unhandled WebSocket event: ${event.type}');
    }
  }
  
  void _handleNewMessage(Map<String, dynamic> data) {
    // This will be handled by MessageProvider
    notifyListeners();
  }
  
  void _handleNewNotification(Map<String, dynamic> data) {
    // This will be handled by NotificationProvider
    notifyListeners();
  }
  
  void _handleBookingUpdate(Map<String, dynamic> data) {
    // This will be handled by BookingProvider
    notifyListeners();
  }
  
  void _handleQuoteUpdate(Map<String, dynamic> data) {
    // This will be handled by QuoteProvider
    notifyListeners();
  }
  
  void _handleDisputeUpdate(Map<String, dynamic> data) {
    // This will be handled by DisputeProvider
    notifyListeners();
  }
  
  void _handlePaymentUpdate(Map<String, dynamic> data) {
    // This will be handled by PaymentProvider
    notifyListeners();
  }
  
  void _handleUserStatusUpdate(Map<String, dynamic> data) {
    // Handle user online/offline status updates
    notifyListeners();
  }
  
  // Public methods for WebSocket operations
  void joinRoom(String roomId) {
    _webSocketService.joinRoom(roomId);
  }
  
  void leaveRoom(String roomId) {
    _webSocketService.leaveRoom(roomId);
  }
  
  void subscribeToUserUpdates(String userId) {
    _webSocketService.subscribeToUserUpdates(userId);
  }
  
  void unsubscribeFromUserUpdates(String userId) {
    _webSocketService.unsubscribeFromUserUpdates(userId);
  }
  
  void sendMessage(String event, Map<String, dynamic> data) {
    _webSocketService.sendMessage(event, data);
  }
  
  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
