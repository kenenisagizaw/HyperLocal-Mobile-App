import '../datasources/remote/payment_api.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  PaymentRepository(this.api);

  final PaymentApi api;

  Future<PaymentInitialization> initializeBookingPayment({
    required String purpose,
    required double amount,
    String? returnUrl, // Optional for Flutter/mobile clients
    required Map<String, dynamic> metadata,
  }) {
    return api.initializeBookingPayment(
      purpose: purpose,
      amount: amount,
      returnUrl: returnUrl,
      metadata: metadata,
    );
  }

  Future<PaymentVerification> verifyPayment(String txRef) {
    return api.verifyPayment(txRef);
  }
}
