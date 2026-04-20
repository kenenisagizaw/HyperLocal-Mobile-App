import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/review_model.dart';

class ReviewApi {
  ReviewApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;

  Future<Review> submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      ApiConstants.reviews,
      data: {'bookingId': bookingId, 'rating': rating, 'comment': comment},
    );
    final map = _unwrapMap(response.data);
    final reviewMap = _extractReviewMap(map);
    return Review.fromJson(reviewMap);
  }

  Future<ProviderReviews> getProviderReviews({
    required String providerId,
    int? skip,
    int? take,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.providerReviews}/$providerId/reviews',
      queryParameters: {
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );
    final map = _unwrapMap(response.data);
    final reviews = _extractReviewList(map);
    final averageRating = _extractAverageRating(map);
    final pagination = _extractPagination(map);
    return ProviderReviews(
      reviews: reviews,
      averageRating: averageRating,
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

  Map<String, dynamic> _extractReviewMap(Map<String, dynamic> map) {
    final data = map['data'] ?? map['review'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return map;
  }

  List<Review> _extractReviewList(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
        ? (map['data'] as Map).cast<String, dynamic>()
        : null;
    final direct = map['reviews'] ?? map['items'] ?? map['data'];
    final list = direct is List
        ? direct
        : direct is Map
        ? (direct['items'] ?? direct['reviews'] ?? direct['data'])
        : data?['reviews'] ?? data?['items'] ?? data?['data'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((item) => Review.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  double _extractAverageRating(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
        ? (map['data'] as Map).cast<String, dynamic>()
        : null;
    final value =
        map['averageRating'] ??
        map['avgRating'] ??
        map['rating'] ??
        data?['averageRating'] ??
        data?['avgRating'] ??
        data?['rating'];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic>? _extractPagination(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
        ? (map['data'] as Map).cast<String, dynamic>()
        : null;
    final pagination =
        map['pagination'] ??
        map['meta'] ??
        map['page'] ??
        data?['pagination'] ??
        data?['meta'] ??
        data?['page'];
    if (pagination is Map<String, dynamic>) {
      return pagination;
    }
    if (pagination is Map) {
      return pagination.cast<String, dynamic>();
    }
    return null;
  }
}

class ProviderReviews {
  ProviderReviews({
    required this.reviews,
    required this.averageRating,
    this.pagination,
  });

  final List<Review> reviews;
  final double averageRating;
  final Map<String, dynamic>? pagination;
}
