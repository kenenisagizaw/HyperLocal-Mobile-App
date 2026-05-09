class ConnectTransaction {
  ConnectTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.reference,
    required this.requestId,
    required this.quoteId,
  });

  final String id;
  final String type;
  final int amount;
  final String description;
  final String status;
  final DateTime createdAt;
  final String reference;
  final String requestId;
  final String quoteId;

  factory ConnectTransaction.fromJson(Map<String, dynamic> json) {
    return ConnectTransaction(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? json['category'] ?? 'unknown').toString(),
      amount: _parseInt(
        json['amount'] ??
            json['connectAmount'] ??
            json['connects'] ??
            json['quantity'],
      ),
      description: (json['description'] ?? json['note'] ?? json['reason'] ?? '')
          .toString(),
      status: (json['status'] ?? json['state'] ?? 'completed').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      reference: (json['reference'] ?? json['transactionId'] ?? '').toString(),
      requestId: (json['requestId'] ?? json['serviceRequestId'] ?? '')
          .toString(),
      quoteId: (json['quoteId'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
