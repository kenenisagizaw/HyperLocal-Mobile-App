class Quote {
  final String id;
  final String requestId;
  final String providerName;
  final double price;
  final String notes;
  final String? providerId;
  final String? providerPhone;
  final String? providerLocation;
  final String? providerImage;
  final double rating;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.requestId,
    required this.providerName,
    required this.price,
    required this.notes,
    this.providerId,
    this.providerPhone,
    this.providerLocation,
    this.providerImage,
    double? rating,
    DateTime? createdAt,
  })  : rating = rating ?? 4.5,
        createdAt = createdAt ?? DateTime.now();
}
