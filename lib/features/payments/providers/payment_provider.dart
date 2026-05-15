import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/error_utils.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({required this.repository});

  final PaymentRepository repository;

  final List<Payment> _payments = [];
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;
  PaymentInitialization? lastInitialization;

  List<Payment> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;

  Future<PaymentInitialization?> initializeBookingPayment({
    required String bookingId,
    required double amount,
    String? serviceRequestId, // Optional metadata
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final initialization = await repository.initializeBookingPayment(
        purpose: "BOOKING_PAYMENT",
        amount: amount,
        metadata: {
          "bookingId": bookingId,
          if (serviceRequestId != null) "serviceRequestId": serviceRequestId,
        },
      );
      lastInitialization = initialization;
      return initialization;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentVerification?> verifyPayment(String txRef) async {
    _setLoading(true);
    _clearErrors();
    try {
      return await repository.verifyPayment(txRef);
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

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

  Payment _paymentFromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      requestId: (json['requestId'] ?? json['serviceRequestId'] ?? '')
          .toString(),
      quoteId: (json['quoteId'] ?? '').toString(),
      payerId: (json['payerId'] ?? json['userId'] ?? '').toString(),
      amount: _parseDouble(json['amount']),
      status: _parsePaymentStatus(json['status'] ?? json['paymentStatus']),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  PaymentStatus _parsePaymentStatus(dynamic value) {
    final normalized = (value ?? '').toString().toLowerCase();
    if (normalized == 'paid' ||
        normalized == 'success' ||
        normalized == 'successful' ||
        normalized == 'completed') {
      return PaymentStatus.paid;
    }
    if (normalized == 'failed' || normalized == 'cancelled') {
      return PaymentStatus.failed;
    }
    return PaymentStatus.pending;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = ErrorUtils.friendlyMessage(
      error,
      fallbackMessage: 'Something went wrong. Please try again.',
    );
  }
}
