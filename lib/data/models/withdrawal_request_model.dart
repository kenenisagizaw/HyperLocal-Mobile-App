class WithdrawalRequest {
  WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final double fee;
  final double netAmount;
  final String method;
  final String status;
  final DateTime createdAt;

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      amount: _parseDouble(json['amount'] ?? json['value'] ?? 0),
      fee: _parseDouble(json['fee'] ?? json['charge'] ?? 0),
      netAmount: _parseDouble(
        json['netAmount'] ?? json['net'] ?? json['payout'] ?? 0,
      ),
      method: (json['method'] ?? json['channel'] ?? 'bank').toString(),
      status: (json['status'] ?? json['state'] ?? 'pending').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
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
