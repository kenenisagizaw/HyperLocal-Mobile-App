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
  final _comment = TextEditingController();

  bool _loading = true;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBooking();
    });
  }

  Future<void> _checkBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<BookingProvider>();
    final booking = await provider.loadBooking(widget.bookingId);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _completed = booking?.status == BookingStatus.completed;
      _error = booking == null ? 'Booking not found' : null;
    });
  }

  Future<void> _submit() async {
    if (!_completed) return;

    final reviewProvider = context.read<ReviewProvider>();

    final res = await reviewProvider.submitReview(
      bookingId: widget.bookingId,
      rating: _rating,
      comment: _comment.text.trim(),
    );

    if (!mounted) return;

    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewProvider.errorMessage ?? 'Failed to submit review',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canReview = _completed;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Your Review',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(),

            const SizedBox(height: 16),

            _card(
              title: 'Rate your experience',
              child: _ratingStars(canReview),
            ),

            const SizedBox(height: 16),

            _card(
              title: 'Share your feedback',
              child: TextField(
                controller: _comment,
                enabled: canReview,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'What went well? What could be improved?',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canReview ? _submit : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  canReview
                      ? 'Submit Review'
                      : 'Complete Booking First',
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.indigo],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your service?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your feedback helps improve quality.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _ratingStars(bool enabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;

        return GestureDetector(
          onTap: enabled
              ? () => setState(() => _rating = star)
              : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _rating == star ? 1.2 : 1.0,
            child: Icon(
              _rating >= star
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 36,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}