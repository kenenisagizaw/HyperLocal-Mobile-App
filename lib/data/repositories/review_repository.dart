import '../datasources/remote/review_api.dart';
import '../models/review_model.dart';

class ReviewRepository {
  ReviewRepository(this.api);

  final ReviewApi api;

  Future<Review> submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) {
    return api.submitReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
  }

  Future<ProviderReviews> fetchProviderReviews({
    required String providerId,
    int? skip,
    int? take,
  }) {
    return api.getProviderReviews(
      providerId: providerId,
      skip: skip,
      take: take,
    );
  }
}
