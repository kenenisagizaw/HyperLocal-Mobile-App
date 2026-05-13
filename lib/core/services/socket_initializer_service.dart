import 'dart:async';

import 'package:flutter/foundation.dart';

import 'websocket_service.dart';

class SocketInitializerService {
  SocketInitializerService({WebSocketService? webSocketService})
      : _webSocketService = webSocketService ?? WebSocketService();

  final WebSocketService _webSocketService;
  bool _isAuthenticated = false;
  Future<void>? _syncFuture;

  void syncAuthentication(bool isAuthenticated) {
    if (_isAuthenticated == isAuthenticated) {
      if (isAuthenticated) {
        unawaited(_webSocketService.reconnectIfNeeded());
      }
      return;
    }

    _isAuthenticated = isAuthenticated;
    _syncFuture = _sync(isAuthenticated);
    unawaited(_syncFuture);
  }

  Future<void> _sync(bool isAuthenticated) async {
    if (isAuthenticated) {
      await _webSocketService.connect();
      return;
    }

    _webSocketService.resetSession();
  }

  Future<void> waitForIdle() async {
    await _syncFuture;
  }
}
