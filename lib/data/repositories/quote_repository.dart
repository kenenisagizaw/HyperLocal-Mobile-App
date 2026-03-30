import '../datasources/remote/quote_api.dart';
import '../models/quote_model.dart';

class QuoteRepository {
  QuoteRepository(this.api);

  final QuoteApi api;

  Future<Quote> submitQuote({
    required String serviceRequestId,
    required double price,
    required String message,
    required int estimatedTime,
  }) {
    return api.submitQuote(
      serviceRequestId: serviceRequestId,
      price: price,
      message: message,
      estimatedTime: estimatedTime,
    );
  }

  Future<List<Quote>> fetchMyQuotes({int? take, int? skip}) {
    return api.getMyQuotes(take: take, skip: skip);
  }

  Future<List<Quote>> fetchQuotesForRequest(String serviceRequestId) {
    return api.getQuotesForRequest(serviceRequestId);
  }

  Future<Quote?> acceptQuote({
    required String requestId,
    required String quoteId,
  }) {
    return api.acceptQuote(requestId: requestId, quoteId: quoteId);
  }

  Future<Quote?> withdrawQuote({
    required String quoteId,
    required String reason,
  }) {
    return api.withdrawQuote(quoteId: quoteId, reason: reason);
  }
}
