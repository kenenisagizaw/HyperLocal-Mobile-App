import '../datasources/remote/payment_api.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  PaymentRepository(this.api);

  final PaymentApi api;

  Future<PaymentInitialization> initializeBookingPayment({
    required double amount,
    required String returnUrl,
    required String bookingId,
  }) {
    return api.initializeBookingPayment(
      amount: amount,
      returnUrl: returnUrl,
      bookingId: bookingId,
    );
  }

  Future<PaymentVerification> verifyPayment(String txRef) {
    return api.verifyPayment(txRef);
  }
}
