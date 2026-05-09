import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/payment_model.dart';
import '../local/local_storage.dart';

class PaymentApi {
  PaymentApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<PaymentInitialization> initializeBookingPayment({
    required String purpose,
    required double amount,
    required Map<String, dynamic> metadata,
  }) async {
    final dio = await _dioFuture;
    final data = {
      'purpose': purpose,
      'amount': amount,
    };
    
    // Add connectAmount to root level if it exists in metadata
    if (metadata.containsKey('connectAmount')) {
      data['connectAmount'] = metadata['connectAmount'];
    }
    
    Logger.info('Payment API - Request URL: ${ApiConstants.baseUrl}${ApiConstants.paymentsChapaInitialize}');
    Logger.info('Payment API - Request payload: $data');
    
    final response = await dio.post(
      ApiConstants.paymentsChapaInitialize,
      data: data,
      options: await _authOptions(),
    );
    
    Logger.info('Payment API - Response status: ${response.statusCode}');
    Logger.info('Payment API - Response data: ${response.data}');
    final map = _unwrapMap(response.data);
    return PaymentInitialization.fromJson(map);
  }

  Future<PaymentVerification> verifyPayment(String txRef) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.paymentsChapaVerify}/$txRef',
      options: await _authOptions(),
    );
    return PaymentVerification.fromJson(response.data);
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    Logger.info('Payment API - Retrieved token: ${token != null ? "exists" : "null"}');
    if (token != null) {
      Logger.info('Payment API - Token length: ${token.length}');
      final previewLength = token.length > 20 ? 20 : token.length;
      Logger.info('Payment API - Token preview: ${token.substring(0, previewLength)}...');
    }
    if (token == null || token.isEmpty) {
      Logger.error('Payment API - No authentication token available');
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
