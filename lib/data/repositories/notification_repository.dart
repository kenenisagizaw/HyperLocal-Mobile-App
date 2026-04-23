import '../datasources/remote/notification_api.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  NotificationRepository(this.api);

  final NotificationApi api;

  Future<List<AppNotification>> fetchNotifications({
    int take = 20,
    int skip = 0,
    bool unreadOnly = false,
  }) {
    return api.getNotifications(take: take, skip: skip, unreadOnly: unreadOnly);
  }

  Future<AppNotification?> markRead(String notificationId) {
    return api.markRead(notificationId);
  }

  Future<int> markAllRead() {
    return api.markAllRead();
  }
}
