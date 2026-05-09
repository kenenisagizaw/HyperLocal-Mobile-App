import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/withdrawal_request_model.dart';
import '../local/local_storage.dart';

class WithdrawalApi {
  WithdrawalApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<WithdrawalRequest> requestWithdrawal({
    required double amount,
    required String method,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? phoneNumber,
  }) async {
    final dio = await _dioFuture;
    Logger.info('Withdrawal API - Requesting withdrawal');

    final response = await dio.post(
      ApiConstants.withdrawalsRequest,
      options: await _authOptions(),
      data: {
        'amount': amount,
        'method': method,
        if (accountName != null && accountName.isNotEmpty)
          'accountName': accountName,
        if (accountNumber != null && accountNumber.isNotEmpty)
          'accountNumber': accountNumber,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
    );

    final map = _unwrapMap(response.data);
    final data = _extractDataMap(map);
    return WithdrawalRequest.fromJson(data ?? map);
  }

  Future<List<WithdrawalRequest>> fetchWithdrawals({
    int? skip,
    int? take,
    String? status,
  }) async {
    final dio = await _dioFuture;
    Logger.info('Withdrawal API - Fetching withdrawal history');

    final response = await dio.get(
      ApiConstants.withdrawals,
      options: await _authOptions(),
      queryParameters: {
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final map = _unwrapMap(response.data);
    final data = _extractDataMap(map);
    final list =
        map['withdrawals'] ?? map['items'] ?? data?['withdrawals'] ?? data?['items'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((item) =>
              WithdrawalRequest.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
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

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> map) {
    final data = map['data'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return null;
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      Logger.error('Withdrawal API - No authentication token available');
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
