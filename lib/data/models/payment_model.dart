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

class PaymentInitialization {
  PaymentInitialization({
    required this.checkoutUrl,
    required this.transactionReference,
    required this.amount,
  });

  final String checkoutUrl;
  final String transactionReference;
  final double amount;

  factory PaymentInitialization.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final checkoutUrl = (data['checkoutUrl'] ?? data['checkout_url'] ?? '')
        .toString();
    final txRef =
        (data['transactionReference'] ??
                data['txRef'] ??
                data['reference'] ??
                '')
            .toString();
    final amountValue = data['amount'] ?? json['amount'];
    final amount = amountValue is num ? amountValue.toDouble() : 0.0;
    return PaymentInitialization(
      checkoutUrl: checkoutUrl,
      transactionReference: txRef,
      amount: amount,
    );
  }
}

class PaymentVerification {
  PaymentVerification({
    required this.transactionReference,
    required this.status,
    required this.verified,
  });

  final String transactionReference;
  final String status;
  final bool verified;

  factory PaymentVerification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final txRef =
        (data['transactionReference'] ??
                data['txRef'] ??
                data['reference'] ??
                '')
            .toString();
    final status = (data['status'] ?? data['paymentStatus'] ?? '').toString();
    final normalized = status.toLowerCase();
    final verified =
        normalized == 'success' ||
        normalized == 'successful' ||
        normalized == 'paid' ||
        normalized == 'completed';
    return PaymentVerification(
      transactionReference: txRef,
      status: status,
      verified: verified,
    );
  }
}
