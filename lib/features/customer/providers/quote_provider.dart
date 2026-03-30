import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/quote_model.dart';
import '../../../data/repositories/quote_repository.dart';

class QuoteProvider extends ChangeNotifier {
  QuoteProvider({required this.repository});

  final QuoteRepository repository;

  final List<Quote> _quotes = [];
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<Quote> get quotes => List.unmodifiable(_quotes);
  bool get isLoading => _isLoading;

  Future<void> loadMyQuotes({int? take, int? skip}) async {
    _setLoading(true);
    _clearErrors();
    try {
      final results = await repository.fetchMyQuotes(take: take, skip: skip);
      _quotes
        ..clear()
        ..addAll(results);
      _sortQuotes();
    } on DioException catch (error) {
      _setError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Quote>> loadQuotesForRequest(String requestId) async {
    _setLoading(true);
    _clearErrors();
    try {
      final results = await repository.fetchQuotesForRequest(requestId);
      _quotes.removeWhere((q) => q.requestId == requestId);
      _quotes.addAll(results);
      _sortQuotes();
      return results;
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Quote?> submitQuote({
    required String serviceRequestId,
    required double price,
    required String message,
    required int estimatedTime,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final created = await repository.submitQuote(
        serviceRequestId: serviceRequestId,
        price: price,
        message: message,
        estimatedTime: estimatedTime,
      );
      _upsertQuote(created);
      return created;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptQuote({
    required String requestId,
    required String quoteId,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final updated = await repository.acceptQuote(
        requestId: requestId,
        quoteId: quoteId,
      );
      if (updated != null) {
        _upsertQuote(updated);
      } else {
        _updateQuoteStatus(quoteId, QuoteStatus.accepted);
      }
      return true;
    } on DioException catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> withdrawQuote({
    required String quoteId,
    required String reason,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final updated = await repository.withdrawQuote(
        quoteId: quoteId,
        reason: reason,
      );
      if (updated != null) {
        _upsertQuote(updated);
      } else {
        _updateQuoteStatus(quoteId, QuoteStatus.withdrawn);
      }
      return true;
    } on DioException catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<Quote> getQuotesForRequest(String requestId) {
    return _quotes.where((q) => q.requestId == requestId).toList();
  }

  List<Quote> getQuotesForRequests(List<String> requestIds) {
    final requestIdSet = requestIds.toSet();
    final results = _quotes.where((q) => requestIdSet.contains(q.requestId));
    final sorted = results.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  void _sortQuotes() {
    _quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _upsertQuote(Quote quote) {
    final index = _quotes.indexWhere((q) => q.id == quote.id);
    if (index >= 0) {
      _quotes[index] = quote;
    } else {
      _quotes.add(quote);
    }
    _sortQuotes();
    notifyListeners();
  }

  void _updateQuoteStatus(String quoteId, QuoteStatus status) {
    final index = _quotes.indexWhere((q) => q.id == quoteId);
    if (index == -1) {
      return;
    }
    final existing = _quotes[index];
    _quotes[index] = Quote(
      id: existing.id,
      requestId: existing.requestId,
      providerName: existing.providerName,
      price: existing.price,
      message: existing.message,
      estimatedTime: existing.estimatedTime,
      providerId: existing.providerId,
      providerPhone: existing.providerPhone,
      providerLocation: existing.providerLocation,
      providerImage: existing.providerImage,
      status: status,
      rating: existing.rating,
      createdAt: existing.createdAt,
    );
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = _extractErrorMessage(error);
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }
}
