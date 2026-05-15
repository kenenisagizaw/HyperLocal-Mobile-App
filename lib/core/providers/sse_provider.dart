import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sse_service.dart';
import '../services/sse_initializer_service.dart';

/// Exposes SSE connection status to the widget tree.
///
/// Replaces [WebSocketProvider]. Owns an [SseInitializerService] and makes
/// connection status observable via [ChangeNotifier].
class SseProvider extends ChangeNotifier {
  SseProvider({SseInitializerService? initializer})
      : _initializer = initializer ?? SseInitializerService() {
    _initialize();
  }

  final SseInitializerService _initializer;

  StreamSubscription<SseConnectionStatus>? _notifStatusSub;
  StreamSubscription<SseConnectionStatus>? _msgStatusSub;
  StreamSubscription<SseConnectionStatus>? _locStatusSub;

  SseConnectionStatus _notificationStatus = SseConnectionStatus.disconnected;
  SseConnectionStatus _messageStatus = SseConnectionStatus.disconnected;
  SseConnectionStatus _locationStatus = SseConnectionStatus.disconnected;

  SseConnectionStatus get notificationStatus => _notificationStatus;
  SseConnectionStatus get messageStatus => _messageStatus;
  SseConnectionStatus get locationStatus => _locationStatus;

  bool get isConnected =>
      _notificationStatus == SseConnectionStatus.connected ||
      _messageStatus == SseConnectionStatus.connected;

  bool get hasError =>
      _notificationStatus == SseConnectionStatus.error ||
      _messageStatus == SseConnectionStatus.error;

  /// Access the underlying SSE services for provider subscriptions.
  SseService get notificationSse => _initializer.notificationSse;
  SseService get messageSse => _initializer.messageSse;
  SseService get locationShareSse => _initializer.locationShareSse;

  /// The initializer, so it can be wired into ProxyProvider for auth sync.
  SseInitializerService get initializer => _initializer;

  void _initialize() {
    _notificationStatus = _initializer.notificationSse.currentStatus;
    _messageStatus = _initializer.messageSse.currentStatus;
    _locationStatus = _initializer.locationShareSse.currentStatus;

    _notifStatusSub =
        _initializer.notificationSse.connectionStatus.listen((status) {
      _notificationStatus = status;
      notifyListeners();
    });

    _msgStatusSub =
        _initializer.messageSse.connectionStatus.listen((status) {
      _messageStatus = status;
      notifyListeners();
    });

    _locStatusSub =
        _initializer.locationShareSse.connectionStatus.listen((status) {
      _locationStatus = status;
      notifyListeners();
    });
  }

  /// Connect all SSE streams (called on app resume, etc.).
  Future<void> connect() async {
    await Future.wait([
      _initializer.notificationSse.connect(),
      _initializer.messageSse.connect(),
      _initializer.locationShareSse.connect(),
    ]);
  }

  /// Disconnect all streams.
  void disconnect() {
    _initializer.notificationSse.disconnect();
    _initializer.messageSse.disconnect();
    _initializer.locationShareSse.disconnect();
  }

  @override
  void dispose() {
    _notifStatusSub?.cancel();
    _msgStatusSub?.cancel();
    _locStatusSub?.cancel();
    super.dispose();
  }
}
