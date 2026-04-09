import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../auth/providers/auth_provider.dart';
import '../bookings/providers/booking_provider.dart';
import 'providers/review_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.providerId,
    required this.bookingId,
  });

  final String providerId;
  final String bookingId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isCheckingBooking = true;
  bool _isBookingCompleted = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingStatus();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingStatus() async {
    setState(() {
      _isCheckingBooking = true;
      _bookingError = null;
    });

    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.loadBooking(widget.bookingId);
    if (!mounted) return;

    final status = booking?.status;
    setState(() {
      _isCheckingBooking = false;
      _isBookingCompleted = status == BookingStatus.completed;
      _bookingError = booking == null
          ? (bookingProvider.errorMessage ?? 'Booking not found.')
          : null;
    });
  }

  Future<void> _submitReview() async {
    if (!_isBookingCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reviews are only allowed after booking completion.'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final reviewProvider = context.read<ReviewProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return;
    }

    final created = await reviewProvider.submitReview(
      bookingId: widget.bookingId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    if (created == null) {
      final message = reviewProvider.errorMessage ?? 'Failed to submit review.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review submitted')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isCheckingBooking)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Checking booking status...'),
                  ],
                ),
              )
            else if (_bookingError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _bookingError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            else if (!_isBookingCompleted)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Booking must be completed before leaving a review.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            const Text(
              'Rate your provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: _isBookingCompleted
                      ? () => setState(() => _rating = star)
                      : null,
                  icon: Icon(
                    _rating >= star ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              enabled: _isBookingCompleted,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBookingCompleted ? _submitReview : null,
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
