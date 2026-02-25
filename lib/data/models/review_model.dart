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
}
