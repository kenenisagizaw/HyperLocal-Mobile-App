import 'dart:convert';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type,
    this.data,
    this.readAt,
  });

  final String id;
  final String? type;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = _parseData(json['data'] ?? json['payload'] ?? json['meta']);
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: json['type']?.toString(),
      title: (json['title'] ?? json['subject'] ?? json['heading'] ?? '')
          .toString(),
      body: (json['body'] ??
              json['message'] ??
              json['content'] ??
              json['text'] ??
              '')
          .toString(),
      data: data,
      readAt: parseDate(json['readAt']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      type: type,
      data: data,
      readAt: readAt ?? this.readAt,
    );
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
