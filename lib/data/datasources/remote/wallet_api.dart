import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/wallet_model.dart';
import '../local/local_storage.dart';

class WalletApi {
  WalletApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<WalletModel> fetchWallet() async {
    final dio = await _dioFuture;
    Logger.info('Wallet API - Fetching wallet data');

    final connectBalance = await _fetchConnectBalance(dio);
    final walletBalance = await _fetchProviderBalance(dio);

    return WalletModel(
      walletBalance: walletBalance,
      connectBalance: connectBalance,
    );
  }

  Future<int> _fetchConnectBalance(Dio dio) async {
    try {
      final response = await dio.get(
        ApiConstants.connects,
        options: await _authOptions(),
      );
      final map = _unwrapMap(response.data);
      final data = _extractDataMap(map);
      return _extractInt(
        data?['connectBalance'] ??
            data?['balance'] ??
            map['connectBalance'] ??
            map['balance'] ??
            map['connects'],
      );
    } catch (e) {
      Logger.error('Wallet API - Failed to fetch connects: $e');
      return 0;
    }
  }

  Future<double> _fetchProviderBalance(Dio dio) async {
    try {
      final response = await dio.get(
        ApiConstants.withdrawalsWallet,
        options: await _authOptions(),
      );
      final map = _unwrapMap(response.data);
      final data = _extractDataMap(map);
      return _extractDouble(
        data?['walletBalance'] ??
            data?['balance'] ??
            map['walletBalance'] ??
            map['balance'],
      );
    } catch (e) {
      Logger.error('Wallet API - Failed to fetch provider wallet: $e');
      return 0.0;
    }
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
    final data = map['data'] ?? map['result'] ?? map['wallet'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return null;
  }

  int _extractInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _extractDouble(dynamic value) {
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

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    Logger.info(
      'Wallet API - Retrieved token: ${token != null ? "exists" : "null"}',
    );
    if (token == null || token.isEmpty) {
      Logger.error('Wallet API - No authentication token available');
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
