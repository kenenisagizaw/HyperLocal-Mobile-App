import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/provider_wallet_model.dart';
import '../../models/wallet_transaction_model.dart';
import '../local/local_storage.dart';

class ProviderWalletApi {
  ProviderWalletApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<ProviderWalletModel> fetchWallet({
    int? skip,
    int? take,
    String? status,
    String? type,
  }) async {
    final dio = await _dioFuture;
    Logger.info('Provider Wallet API - Fetching wallet');

    final response = await dio.get(
      ApiConstants.withdrawalsWallet,
      options: await _authOptions(),
      queryParameters: {
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );

    final map = _unwrapMap(response.data);
    final data = _extractDataMap(map);
    final transactions = _extractTransactionList(map, data);
    final pagination = _extractPagination(map, data);

    return ProviderWalletModel(
      walletBalance: _extractDouble(
        data?['walletBalance'] ??
            data?['balance'] ??
            map['walletBalance'] ??
            map['balance'],
      ),
      totalEarned: _extractDouble(
        data?['totalEarned'] ??
            data?['earned'] ??
            map['totalEarned'] ??
            map['earned'],
      ),
      totalWithdrawn: _extractDouble(
        data?['totalWithdrawn'] ??
            data?['withdrawn'] ??
            map['totalWithdrawn'] ??
            map['withdrawn'],
      ),
      pendingWithdrawals: _extractDouble(
        data?['pendingWithdrawals'] ??
            data?['pending'] ??
            map['pendingWithdrawals'] ??
            map['pending'],
      ),
      availableToWithdraw: _extractDouble(
        data?['availableToWithdraw'] ??
            data?['available'] ??
            map['availableToWithdraw'] ??
            map['available'],
      ),
      currency: (data?['currency'] ?? map['currency'] ?? 'ETB').toString(),
      withdrawalFeePercent: _extractNullableDouble(
        data?['withdrawalFeePercent'] ??
            data?['withdrawalFee'] ??
            map['withdrawalFeePercent'] ??
            map['withdrawalFee'],
      ),
      transactions: transactions,
      pagination: pagination,
    );
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

  List<WalletTransaction> _extractTransactionList(
    Map<String, dynamic> map,
    Map<String, dynamic>? data,
  ) {
    final direct =
        map['transactions'] ?? map['items'] ?? map['history'] ?? map['data'];
    final list = direct is List
        ? direct
        : direct is Map
        ? (direct['transactions'] ?? direct['items'] ?? direct['history'])
        : data?['transactions'] ?? data?['items'] ?? data?['history'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map(
            (item) => WalletTransaction.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    return const [];
  }

  Map<String, dynamic>? _extractPagination(
    Map<String, dynamic> map,
    Map<String, dynamic>? data,
  ) {
    final pagination =
        map['pagination'] ?? map['meta'] ?? map['page'] ?? data?['pagination'];
    if (pagination is Map<String, dynamic>) {
      return pagination;
    }
    if (pagination is Map) {
      return pagination.cast<String, dynamic>();
    }
    return null;
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

  double? _extractNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return _extractDouble(value);
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      Logger.error('Provider Wallet API - No authentication token available');
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
