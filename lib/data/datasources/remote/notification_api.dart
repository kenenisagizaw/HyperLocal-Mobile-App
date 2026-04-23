import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/app_notification_model.dart';

class NotificationApi {
  NotificationApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;

  Future<List<AppNotification>> getNotifications({
    int take = 20,
    int skip = 0,
    bool unreadOnly = false,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.notifications,
      queryParameters: {'take': take, 'skip': skip, 'unreadOnly': unreadOnly},
    );
    final map = _unwrapMap(response.data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<AppNotification?> markRead(String notificationId) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.notifications}/$notificationId/read',
    );
    final map = _unwrapMap(response.data);
    final data = map['data'] is Map ? map['data'] as Map : null;
    final notif = data?['notification'] ?? map['notification'];
    if (notif is Map) {
      return AppNotification.fromJson(notif.cast<String, dynamic>());
    }
    return null;
  }

  Future<int> markAllRead() async {
    final dio = await _dioFuture;
    final response = await dio.patch(ApiConstants.notificationsReadAll);
    final map = _unwrapMap(response.data);
    final data = map['data'] is Map ? map['data'] as Map : null;
    final value = data?['updatedCount'] ?? map['updatedCount'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
        ? (map['data'] as Map).cast<String, dynamic>()
        : null;
    final direct = map['notifications'] ?? map['items'] ?? map['data'];
    final list = direct is List
        ? direct
        : direct is Map
        ? (direct['notifications'] ?? direct['items'] ?? direct['data'])
        : data?['notifications'] ?? data?['items'] ?? data?['data'];
    if (list is List) {
      return list;
    }
    return const [];
  }
}
