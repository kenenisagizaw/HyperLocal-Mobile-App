class Review {
  Review({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String providerId;
  final String reviewerId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      requestId: (json['requestId'] ?? json['serviceRequestId'] ?? '')
          .toString(),
      providerId: (json['providerId'] ?? json['provider']?['id'] ?? '')
          .toString(),
      reviewerId: (json['reviewerId'] ?? json['userId'] ?? '').toString(),
      rating: _parseRating(json['rating']),
      comment: (json['comment'] ?? json['message'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static int _parseRating(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
