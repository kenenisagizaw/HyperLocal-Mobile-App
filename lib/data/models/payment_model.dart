class Payment {
  Payment({
    required this.id,
    required this.requestId,
    required this.quoteId,
    required this.payerId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String quoteId;
  final String payerId;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
}

enum PaymentStatus { pending, paid, failed }
