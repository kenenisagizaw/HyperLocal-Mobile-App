import 'package:flutter/material.dart';

import '../data/models/quote_model.dart';

class QuoteProvider extends ChangeNotifier {
  List<Quote> quotes = [
    Quote(
      id: '1',
      requestId: '1',
      providerName: 'Abebe',
      price: 1400,
      notes: 'Can fix today',
      providerId: 'provider-1',
      providerPhone: '0911 223 344',
      providerLocation: 'Bole, Addis Ababa',
      rating: 4.8,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Quote(
      id: '2',
      requestId: '1',
      providerName: 'Mekdes',
      price: 1450,
      notes: 'Available tomorrow',
      providerId: 'provider-2',
      providerPhone: '0900 556 677',
      providerLocation: 'Sar Bet, Addis Ababa',
      rating: 4.6,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  void addQuote(Quote quote) {
    quotes.add(quote);
    notifyListeners();
  }

  List<Quote> getQuotesForRequest(String requestId) {
    return quotes.where((q) => q.requestId == requestId).toList();
  }

  List<Quote> getQuotesForRequests(List<String> requestIds) {
    final requestIdSet = requestIds.toSet();
    final results = quotes.where((q) => requestIdSet.contains(q.requestId));
    final sorted = results.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
