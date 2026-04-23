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
    final data = json['data'] is Map
        ? (json['data'] as Map).cast<String, dynamic>()
        : null;
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: json['type']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      data: data,
      readAt: _parseDate(json['readAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
