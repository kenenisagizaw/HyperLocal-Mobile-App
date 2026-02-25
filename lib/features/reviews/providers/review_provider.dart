import 'package:flutter/material.dart';

import '../../../data/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final List<Review> _reviews = [];

  List<Review> get reviews => List.unmodifiable(_reviews);

  void addReview(Review review) {
    _reviews.add(review);
    notifyListeners();
  }

  List<Review> getReviewsForProvider(String providerId) {
    return _reviews.where((r) => r.providerId == providerId).toList();
  }
}
