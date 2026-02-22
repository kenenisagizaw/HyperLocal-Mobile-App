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
    ),
    Quote(
      id: '2',
      requestId: '1',
      providerName: 'Mekdes',
      price: 1450,
      notes: 'Available tomorrow',
    ),
  ];

  void addQuote(Quote quote) {
    quotes.add(quote);
    notifyListeners();
  }

  List<Quote> getQuotesForRequest(String requestId) {
    return quotes.where((q) => q.requestId == requestId).toList();
  }
}
