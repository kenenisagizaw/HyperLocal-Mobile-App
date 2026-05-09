class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    required this.reference,
    required this.createdAt,
    required this.bookingId,
    required this.requestId,
  });

  final String id;
  final String type;
  final double amount;
  final String status;
  final String description;
  final String reference;
  final DateTime createdAt;
  final String bookingId;
  final String requestId;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? json['category'] ?? 'payment').toString(),
      amount: _parseDouble(json['amount'] ?? json['value'] ?? 0),
      status: (json['status'] ?? json['state'] ?? 'completed').toString(),
      description: (json['description'] ?? json['note'] ?? json['reason'] ?? '')
          .toString(),
      reference: (json['reference'] ?? json['transactionId'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      bookingId: (json['bookingId'] ?? '').toString(),
      requestId: (json['requestId'] ?? json['serviceRequestId'] ?? '')
          .toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
