import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/review_model.dart';
import '../../data/models/user_model.dart';
import '../customer/providers/customer_directory_provider.dart';
import '../provider/widgets/user_avatar.dart';
import 'providers/review_provider.dart';

class ProviderReviewsScreen extends StatefulWidget {
  const ProviderReviewsScreen({
    super.key,
    required this.providerId,
    this.providerName,
  });

  final String providerId;
  final String? providerName;

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  static const int _pageSize = 10;
  int _take = _pageSize;
  final Set<String> _requestedReviewerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    await context.read<ReviewProvider>().loadProviderReviews(
      providerId: widget.providerId,
      take: _take,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final customerDirectory = context.watch<CustomerDirectoryProvider>();
    final reviews = reviewProvider.getReviewsForProvider(widget.providerId);
    final averageRating = reviewProvider.averageRating;

    _prefetchReviewers(customerDirectory, reviews);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerName == null || widget.providerName!.isEmpty
            ? 'Provider Reviews'
            : '${widget.providerName} Reviews'),
      ),
      body: reviewProvider.isLoading && reviews.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _take = _pageSize;
                await _loadReviews();
              },
              child: reviews.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _RatingHeader(
                          averageRating: averageRating,
                          reviewCount: 0,
                        ),
                        const SizedBox(height: 16),
                        const Center(child: Text('No reviews yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _RatingHeader(
                            averageRating: averageRating,
                            reviewCount: reviews.length,
                          );
                        }
                        if (index == reviews.length + 1) {
                          return _buildLoadMoreButton(reviews);
                        }
                        final review = reviews[index - 1];
                        final reviewer = customerDirectory.getCustomerById(
                          review.reviewerId,
                        );
                        return _ReviewCard(
                          review: review,
                          reviewer: reviewer,
                        );
                      },
                    ),
            ),
    );
  }

  void _prefetchReviewers(
    CustomerDirectoryProvider customerDirectory,
    List<Review> reviews,
  ) {
    for (final review in reviews) {
      final reviewerId = review.reviewerId;
      if (reviewerId.isEmpty) {
        continue;
      }
      if (_requestedReviewerIds.contains(reviewerId)) {
        continue;
      }
      final cached = customerDirectory.getCustomerById(reviewerId);
      if (cached != null) {
        _requestedReviewerIds.add(reviewerId);
        continue;
      }
      _requestedReviewerIds.add(reviewerId);
      customerDirectory.fetchCustomerById(reviewerId);
    }
  }

  Widget _buildLoadMoreButton(List<Review> reviews) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _take += _pageSize;
          });
          _loadReviews();
        },
        child: Text('Load more (${reviews.length})'),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.reviewer});

  final Review review;
  final UserModel? reviewer;

  @override
  Widget build(BuildContext context) {
    final reviewerName = reviewer?.name ?? 'Customer';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: reviewerName,
                imagePath: reviewer?.profilePicture,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.star, color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 6),
              Text(
                '${review.rating}/5',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _RatingHeader extends StatelessWidget {
  const _RatingHeader({
    required this.averageRating,
    required this.reviewCount,
  });

  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final ratingText = reviewCount == 0
        ? 'No ratings yet'
        : '${averageRating.toStringAsFixed(1)} / 5';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ratingText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _StarRow(averageRating: averageRating),
                const SizedBox(height: 4),
                Text(
                  reviewCount == 1
                      ? '1 review'
                      : '$reviewCount reviews',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.averageRating});

  final double averageRating;

  @override
  Widget build(BuildContext context) {
    final fullStars = averageRating.floor().clamp(0, 5);
    final hasHalfStar = (averageRating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 18);
        }
        if (index == fullStars && hasHalfStar) {
          return const Icon(
            Icons.star_half_rounded,
            color: Colors.amber,
            size: 18,
          );
        }
        return const Icon(
          Icons.star_border_rounded,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }
}
