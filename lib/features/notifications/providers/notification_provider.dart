import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/models/app_notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this.repository});

  final NotificationRepository repository;

  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => n.readAt == null).length;

  Future<void> loadNotifications({
    int take = 20,
    int skip = 0,
    bool unreadOnly = false,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final result = await repository.fetchNotifications(
        take: take,
        skip: skip,
        unreadOnly: unreadOnly,
      );
      _notifications
        ..clear()
        ..addAll(result);
      _sortNotifications();
    } on DioException catch (error) {
      _setError(error);
    } finally {
      _setLoading(false);
    }
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
