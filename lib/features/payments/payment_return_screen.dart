import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bookings/booking_detail_screen.dart';
import '../bookings/providers/booking_provider.dart';
import 'providers/payment_provider.dart';

class PaymentReturnScreen extends StatefulWidget {
  const PaymentReturnScreen({super.key, required this.txRef, this.bookingId});

  final String txRef;
  final String? bookingId;

  @override
  State<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends State<PaymentReturnScreen> {
  bool _isVerifying = false;
  bool? _verified;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _statusMessage = null;
    });

    final paymentProvider = context.read<PaymentProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final result = await paymentProvider.verifyPayment(widget.txRef);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isVerifying = false;
        _verified = false;
        _statusMessage =
            paymentProvider.errorMessage ?? 'Payment verification failed.';
      });
      return;
    }

    if (result.verified) {
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        await bookingProvider.loadBooking(widget.bookingId!);
      }
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verified = true;
        _statusMessage = 'Payment verified.';
      });
      return;
    }

    setState(() {
      _isVerifying = false;
      _verified = false;
      _statusMessage = 'Payment not confirmed yet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.bookingId;
    final title = _verified == true
        ? 'Payment Verified'
        : _verified == false
            ? 'Payment Pending'
            : 'Verifying Payment';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference: ${widget.txRef}'),
            const SizedBox(height: 12),
            if (_isVerifying) const LinearProgressIndicator(),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(_statusMessage!),
            ],
            const SizedBox(height: 24),
            if (!_isVerifying)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verify,
                  child: const Text('Retry Verification'),
                ),
              ),
            if (bookingId != null && bookingId.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
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
