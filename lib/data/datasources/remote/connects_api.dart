import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/connect_transaction_model.dart';
import '../../models/connect_wallet_model.dart';
import '../local/local_storage.dart';

class ConnectsApi {
  ConnectsApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<ConnectWallet> fetchConnects({int? skip, int? take}) async {
    final dio = await _dioFuture;
    Logger.info('Connects API - Fetching connects');

    final response = await dio.get(
      ApiConstants.connects,
      options: await _authOptions(),
      queryParameters: {
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );

    final map = _unwrapMap(response.data);
    final data = _extractDataMap(map);
    final balance = _extractInt(
      data?['connectBalance'] ??
          data?['balance'] ??
          map['connectBalance'] ??
          map['balance'] ??
          map['connects'],
    );
    final transactions = _extractTransactionList(map, data);
    final pagination = _extractPagination(map, data);

    return ConnectWallet(
      connectBalance: balance,
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

  List<ConnectTransaction> _extractTransactionList(
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
            (item) => ConnectTransaction.fromJson(item.cast<String, dynamic>()),
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

  int _extractInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      Logger.error('Connects API - No authentication token available');
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
