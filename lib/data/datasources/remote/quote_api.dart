import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../local/local_storage.dart';
import '../../models/quote_model.dart';

class QuoteApi {
  QuoteApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<Quote> submitQuote({
    required String serviceRequestId,
    required double price,
    required String message,
    required int estimatedTime,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      ApiConstants.quotes,
      data: {
        'serviceRequestId': serviceRequestId,
        'price': price,
        'message': message,
        'estimatedTime': estimatedTime,
      },
      options: await _authOptions(),
    );
    return _parseQuote(response.data);
  }

  Future<List<Quote>> getMyQuotes({int? take, int? skip}) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.quotesMine,
      options: await _authOptions(),
      queryParameters: {
        if (take != null) 'take': take,
        if (skip != null) 'skip': skip,
      },
    );
    return _parseQuoteList(response.data);
  }

  Future<List<Quote>> getQuotesForRequest(String serviceRequestId) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.quotesForRequest}/$serviceRequestId',
      options: await _authOptions(),
    );
    return _parseQuoteList(response.data);
  }

  Future<Quote?> acceptQuote({
    required String requestId,
    required String quoteId,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      '${ApiConstants.quotesAccept}/$requestId/accept',
      data: {'quoteId': quoteId},
      options: await _authOptions(),
    );
    return _tryParseQuote(response.data);
  }

  Future<Quote?> withdrawQuote({
    required String quoteId,
    required String reason,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      '${ApiConstants.quotes}/$quoteId/withdraw',
      data: {'reason': reason},
      options: await _authOptions(),
    );
    return _tryParseQuote(response.data);
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Quote _parseQuote(dynamic data) {
    final map = _unwrapMap(data);
    final quoteMap = _extractQuoteMap(map);
    return Quote.fromJson(quoteMap);
  }

  Quote? _tryParseQuote(dynamic data) {
    final map = _unwrapMap(data);
    final quoteMap = _extractQuoteMap(map, allowEmpty: true);
    if (quoteMap.isEmpty) {
      return null;
    }
    return Quote.fromJson(quoteMap);
  }

  List<Quote> _parseQuoteList(dynamic data) {
    final map = _unwrapMap(data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => Quote.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _extractQuoteMap(
    Map<String, dynamic> map, {
    bool allowEmpty = false,
  }) {
    final data = map['data'] ?? map['quote'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      if (data['quote'] is Map) {
        return (data['quote'] as Map).cast<String, dynamic>();
      }
      return data;
    }
    if (map is Map<String, dynamic>) {
      return allowEmpty ? map : map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final direct = map['data'] ?? map['items'] ?? map['quotes'];
    if (direct is List) {
      return direct;
    }

    if (direct is Map) {
      final nested = direct['items'] ?? direct['quotes'] ?? direct['data'];
      if (nested is List) {
        return nested;
      }
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
}
