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
  State<ProviderReviewsScreen> createState() =>
      _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState
    extends State<ProviderReviewsScreen> {
  static const int _pageSize = 10;
  int _take = _pageSize;

  final Set<String> _requested = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadProviderReviews(
            providerId: widget.providerId,
            take: _take,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final customerDir =
        context.watch<CustomerDirectoryProvider>();

    final reviews = reviewProvider
        .getReviewsForProvider(widget.providerId);

    final avg = reviewProvider.averageRating;

    _prefetch(customerDir, reviews);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.providerName?.isEmpty ?? true
              ? 'Reviews'
              : '${widget.providerName} Reviews',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: reviewProvider.isLoading && reviews.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _take = _pageSize;
                await context
                    .read<ReviewProvider>()
                    .loadProviderReviews(
                      providerId: widget.providerId,
                      take: _take,
                    );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RatingCard(
                    avg: avg,
                    count: reviews.length,
                  ),
                  const SizedBox(height: 16),

                  if (reviews.isEmpty)
                    const _EmptyState()
                  else
                    ...reviews.map((r) {
                      final reviewer =
                          customerDir.getCustomerById(
                        r.reviewerId,
                      );

                      return _ReviewTile(
                        review: r,
                        user: reviewer,
                      );
                    }),

                  const SizedBox(height: 16),

                  if (reviews.isNotEmpty)
                    _LoadMore(
                      count: reviews.length,
                      onTap: () async {
                        setState(() => _take += _pageSize);
                        await context
                            .read<ReviewProvider>()
                            .loadProviderReviews(
                              providerId: widget.providerId,
                              take: _take,
                            );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  void _prefetch(CustomerDirectoryProvider dir,
      List<Review> reviews) {
    for (final r in reviews) {
      if (_requested.contains(r.reviewerId)) continue;
      _requested.add(r.reviewerId);
      dir.fetchCustomerById(r.reviewerId);
    }
  }
}

/* ---------------- UI ---------------- */

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.avg, required this.count});

  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count == 0
                    ? 'No ratings yet'
                    : '${avg.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count reviews',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.user,
  });

  final Review review;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: user?.name ?? 'User',
                imagePath: user?.profilePicture,
                radius: 18,
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  user?.name ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              _stars(review.rating),

              const SizedBox(width: 8),

              Text(
                _date(review.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            review.comment,
            style: const TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        ),
      ),
    );
  }

  String _date(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: onTap,
        child: Text('Load more ($count)'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.star_border,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}