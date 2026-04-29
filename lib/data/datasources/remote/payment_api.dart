import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/payment_model.dart';
import '../local/local_storage.dart';

class PaymentApi {
  PaymentApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<PaymentInitialization> initializeBookingPayment({
    required double amount,
    required String returnUrl,
    required String bookingId,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      ApiConstants.paymentsChapaInitialize,
      data: {
        'purpose': 'BOOKING_PAYMENT',
        'amount': amount,
        'returnUrl': returnUrl,
        'metadata': {'bookingId': bookingId},
      },
      options: await _authOptions(),
    );
    final map = _unwrapMap(response.data);
    return PaymentInitialization.fromJson(map);
  }

  Future<PaymentVerification> verifyPayment(String txRef) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.paymentsChapaVerify}/$txRef',
      options: await _authOptions(),
    );
    final map = _unwrapMap(response.data);
    return PaymentVerification.fromJson(map);
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
