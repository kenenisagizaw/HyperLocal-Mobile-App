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
    
    final response = await dio.get(
      ApiConstants.wallet,
      options: await _authOptions(),
    );
    
    Logger.info('Wallet API - Response status: ${response.statusCode}');
    Logger.info('Wallet API - Response data: ${response.data}');
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data['data'] != null) {
        return WalletModel.fromJson(data['data']);
      } else {
        throw Exception('Invalid wallet data format');
      }
    } else {
      throw Exception('Failed to fetch wallet data: ${response.statusCode}');
    }
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    Logger.info('Wallet API - Retrieved token: ${token != null ? "exists" : "null"}');
    if (token == null || token.isEmpty) {
      Logger.error('Wallet API - No authentication token available');
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
