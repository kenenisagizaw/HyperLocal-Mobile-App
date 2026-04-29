import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/payment_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../bookings/booking_detail_screen.dart';
import '../bookings/providers/booking_provider.dart';
import '../reviews/review_screen.dart';
import 'providers/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.request,
    required this.quote,
    this.bookingId,
  });

  final ServiceRequest request;
  final Quote quote;
  final String? bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentInitialization? _initialization;
  bool _didLaunchCheckout = false;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoStarted) return;
      _autoStarted = true;
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        _startPayment();
      }
    });
  }

  Future<void> _startPayment() async {
    if (widget.bookingId == null || widget.bookingId!.isEmpty) {
      _showSnack('Booking ID is missing.');
      return;
    }
    final paymentProvider = context.read<PaymentProvider>();
    final initialization = await paymentProvider.initializeBookingPayment(
      bookingId: widget.bookingId!,
      amount: widget.quote.price,
      returnUrl:
          'myapp://payment/chapa/callback?bookingId=${Uri.encodeComponent(widget.bookingId!)}',
    );
    if (!mounted) return;
    if (initialization == null) {
      _showSnack(paymentProvider.errorMessage ?? 'Failed to start payment.');
      return;
    }

    final uri = Uri.tryParse(initialization.checkoutUrl);
    if (uri == null) {
      _showSnack('Invalid checkout URL.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      _showSnack('Unable to open checkout.');
      return;
    }

    setState(() {
      _initialization = initialization;
      _didLaunchCheckout = true;
    });
  }

  Future<void> _verifyPayment() async {
    final txRef = _initialization?.transactionReference;
    if (txRef == null || txRef.isEmpty) {
      _showSnack('Missing transaction reference.');
      return;
    }
    final paymentProvider = context.read<PaymentProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final result = await paymentProvider.verifyPayment(txRef);
    if (!mounted) return;
    if (result == null) {
      _showSnack(paymentProvider.errorMessage ?? 'Payment verification failed.');
      return;
    }
    if (!result.verified) {
      _showSnack('Payment not confirmed yet.');
      return;
    }

    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      await bookingProvider.loadBooking(widget.bookingId!);
    }

    if (!mounted) return;
    _showSnack('Payment verified.');
    Navigator.pop(context);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final bookingId = widget.bookingId;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Service', value: widget.request.category),
            _SummaryRow(label: 'Provider', value: widget.quote.providerName),
            _SummaryRow(
              label: 'Total',
              value: '\$${widget.quote.price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 20),
            if (_initialization != null) ...[
              Text(
                'Transaction: ${_initialization!.transactionReference}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: paymentProvider.isLoading ? null : _startPayment,
                child: Text(
                  paymentProvider.isLoading ? 'Starting...' : 'Pay Now',
                ),
              ),
            ),
            if (_didLaunchCheckout) ...[
              const SizedBox(height: 16),
              Text(
                'Complete the payment in your browser, then tap verify.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: paymentProvider.isLoading ? null : _verifyPayment,
                  child: Text(
                    paymentProvider.isLoading
                        ? 'Verifying...'
                        : 'I have paid',
                  ),
                ),
              ),
            ],
            if (bookingId != null && bookingId.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(
                          bookingId: bookingId,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.payment,
    required this.request,
    required this.quote,
    this.bookingId,
  });

  final Payment payment;
  final ServiceRequest request;
  final Quote quote;
  final String? bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Successful',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Request: ${request.category}'),
            const SizedBox(height: 6),
            Text('Amount: \$${payment.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text('Status: ${payment.status.name}'),
            if (bookingId != null) ...[
              const SizedBox(height: 6),
              Text('Booking ID: $bookingId'),
            ],
            const SizedBox(height: 24),
            if (bookingId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingDetailScreen(bookingId: bookingId!),
                      ),
                    );
                  },
                  child: const Text('View Booking'),
                ),
              ),
            if (bookingId != null) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: quote.providerId == null || bookingId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              providerId: quote.providerId!,
                              bookingId: bookingId!,
                            ),
                          ),
                        );
                      },
                child: const Text('Leave a Review'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
