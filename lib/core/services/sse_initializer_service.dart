import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../services/sse_service.dart';

/// Manages the three SSE stream connections.
///
/// Replaces [SocketInitializerService]. Call [syncAuthentication] whenever the
/// user's auth state changes (login/logout) so the streams are
/// connected/disconnected accordingly.
class SseInitializerService {
  SseInitializerService({
    SseService? notificationService,
    SseService? messageService,
    SseService? locationShareService,
  })  : notificationSse =
            notificationService ?? SseService(streamPath: ApiConstants.notificationsStream),
        messageSse =
            messageService ?? SseService(streamPath: ApiConstants.messageStream),
        locationShareSse =
            locationShareService ?? SseService(streamPath: ApiConstants.locationShareStream);

  final SseService notificationSse;
  final SseService messageSse;
  final SseService locationShareSse;

  bool _isAuthenticated = false;
  Future<void>? _syncFuture;

  /// React to authentication state changes.
  void syncAuthentication(bool isAuthenticated) {
    if (_isAuthenticated == isAuthenticated) {
      if (isAuthenticated) {
        // Already authenticated — just ensure streams are alive.
        unawaited(notificationSse.reconnectIfNeeded());
        unawaited(messageSse.reconnectIfNeeded());
        unawaited(locationShareSse.reconnectIfNeeded());
      }
      return;
    }

    _isAuthenticated = isAuthenticated;
    _syncFuture = _sync(isAuthenticated);
    unawaited(_syncFuture);
  }

  Future<void> _sync(bool isAuthenticated) async {
    if (isAuthenticated) {
      debugPrint('SSE initializer: connecting streams');
      await Future.wait([
        notificationSse.connect(),
        messageSse.connect(),
        locationShareSse.connect(),
      ]);
      return;
    }

    debugPrint('SSE initializer: disconnecting streams');
    notificationSse.disconnect();
    messageSse.disconnect();
    locationShareSse.disconnect();
  }

  Future<void> waitForIdle() async {
    await _syncFuture;
  }
}
