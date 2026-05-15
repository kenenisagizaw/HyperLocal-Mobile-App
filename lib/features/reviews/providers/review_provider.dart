import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/error_utils.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({required this.repository});

  final ReviewRepository repository;

  final List<Review> _reviews = [];
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;
  double averageRating = 0;

  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;

  Future<Review?> submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final review = await repository.submitReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      _reviews.insert(0, review);
      return review;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Review>> loadProviderReviews({
    required String providerId,
    int? skip,
    int? take,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final result = await repository.fetchProviderReviews(
        providerId: providerId,
        skip: skip,
        take: take,
      );
      _reviews
        ..clear()
        ..addAll(result.reviews);
      averageRating = result.averageRating;
      return _reviews;
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
  }

  List<Review> getReviewsForProvider(String providerId) {
    return _reviews.where((r) => r.providerId == providerId).toList();
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
    errorMessage = ErrorUtils.friendlyMessage(
      error,
      fallbackMessage: 'Something went wrong. Please try again.',
    );
  }
}
