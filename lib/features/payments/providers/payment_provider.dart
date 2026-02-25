import 'package:flutter/material.dart';

import '../../../data/models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final List<Payment> _payments = [];

  List<Payment> get payments => List.unmodifiable(_payments);

  Payment createPayment({
    required String requestId,
    required String quoteId,
    required String payerId,
    required double amount,
  }) {
    final payment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requestId: requestId,
      quoteId: quoteId,
      payerId: payerId,
      amount: amount,
      status: PaymentStatus.paid,
      createdAt: DateTime.now(),
    );
    _payments.add(payment);
    notifyListeners();
    return payment;
  }
}
