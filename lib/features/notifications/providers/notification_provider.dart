import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/sse_service.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this.repository});

  final NotificationRepository repository;

  SseService? _sseService;
  final List<AppNotification> _notifications = [];
  final Set<String> _knownIds = {};
  final StreamController<AppNotification> _incomingController =
      StreamController<AppNotification>.broadcast();
  StreamSubscription<SseEvent>? _sseSub;
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;
  bool _hasLoadedOnce = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  Stream<AppNotification> get incomingNotifications =>
      _incomingController.stream;

  int get unreadCount => _notifications.where((n) => n.readAt == null).length;

  /// Attach the notification SSE stream.
  void attachSse(SseService sseService) {
    if (_sseService == sseService) return;
    _sseSub?.cancel();
    _sseService = sseService;

    _sseSub = sseService.events.listen((event) {
      switch (event.event) {
        case 'notification.created':
          _handleNotificationCreated(event.data);
          break;
        case 'notification.read':
          _handleNotificationRead(event.data);
          break;
        case 'notification.read_all':
          _handleAllNotificationsRead();
          break;
      }
    });
  }

  Future<List<AppNotification>> loadNotifications({
    int take = 20,
    int skip = 0,
    bool unreadOnly = false,
  }) async {
    _setLoading(true);
    _clearErrors();
    List<AppNotification> newlyAdded = const [];
    try {
      final result = await repository.fetchNotifications(
        take: take,
        skip: skip,
        unreadOnly: unreadOnly,
      );
      if (_hasLoadedOnce) {
        newlyAdded = result
            .where((notification) => !_knownIds.contains(notification.id))
            .toList();
      }
      _notifications
        ..clear()
        ..addAll(result);
      _sortNotifications();
      _knownIds
        ..clear()
        ..addAll(
          result
              .map((notification) => notification.id)
              .where((id) => id.isNotEmpty),
        );
      _hasLoadedOnce = true;
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
    return newlyAdded;
  }

  Future<void> markRead(String notificationId) async {
    _clearErrors();
    try {
      final updated = await repository.markRead(notificationId);
      if (updated != null) {
        final index = _notifications.indexWhere((n) => n.id == updated.id);
        if (index >= 0) {
          _notifications[index] = updated;
        }
      } else {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index >= 0) {
          _notifications[index] = _notifications[index].copyWith(
            readAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
    } on DioException catch (error) {
      _setError(error);
    }
  }

  void _upsertNotification(
    AppNotification notification, {
    required bool fromStream,
  }) {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      _notifications[index] = notification;
    } else {
      _notifications.insert(0, notification);
    }
    if (notification.id.isNotEmpty) {
      _knownIds.add(notification.id);
    }
    if (fromStream) {
      _sortNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _clearErrors();
    try {
      await repository.markAllRead();
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(readAt: DateTime.now());
      }
      notifyListeners();
    } on DioException catch (error) {
      _setError(error);
    }
  }

  void _sortNotifications() {
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = _extractErrorMessage(error);
  }

  void _handleNotificationCreated(Map<String, dynamic> data) {
    try {
      final payload = data['notification'] is Map
          ? (data['notification'] as Map).cast<String, dynamic>()
          : data;
      final notification = AppNotification.fromJson(payload);
      _upsertNotification(notification, fromStream: true);
      _incomingController.add(notification);
    } catch (e) {
      debugPrint('Error handling notification.created event: $e');
    }
  }

  void _handleNotificationRead(Map<String, dynamic> data) {
    final notificationId = (data['notificationId'] ?? data['id'] ?? '')
        .toString();
    if (notificationId.isEmpty) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) return;

    final readAt = AppNotification.parseDate(data['readAt']) ?? DateTime.now();
    _notifications[index] = _notifications[index].copyWith(readAt: readAt);
    notifyListeners();
  }

  void _handleAllNotificationsRead() {
    final readAt = DateTime.now();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(readAt: readAt);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _incomingController.close();
    super.dispose();
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }
}
