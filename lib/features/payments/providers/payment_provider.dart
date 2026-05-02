import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
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
    String? returnUrl, // Optional for Flutter/mobile clients
    String? serviceRequestId, // Optional metadata
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final initialization = await repository.initializeBookingPayment(
        purpose: "BOOKING_PAYMENT",
        amount: amount,
        returnUrl: returnUrl ?? ApiConstants.paymentReturnUrl,
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
    errorMessage = _extractErrorMessage(error);
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }
}
