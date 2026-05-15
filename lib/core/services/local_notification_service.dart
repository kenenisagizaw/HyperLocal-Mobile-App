import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static const String channelId = 'app_notifications';
  static const String channelName = 'App Notifications';
  static const String channelDescription =
      'Heads-up notifications for realtime updates.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings);
    await _createAndroidChannel();
    await _requestAndroidPermissions();

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      ),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payloadData = <String, dynamic>{
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
    };

    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payloadData.isEmpty ? null : jsonEncode(payloadData),
    );
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await android.createNotificationChannel(channel);
  }

  Future<void> _requestAndroidPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    try {
      await android.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }
}
