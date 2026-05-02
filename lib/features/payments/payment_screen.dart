import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/enums.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../bookings/booking_detail_screen.dart';
import '../bookings/providers/booking_provider.dart';
import '../reviews/review_screen.dart';
import 'providers/payment_provider.dart';
import 'webview_payment_screen.dart';

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
  bool _autoStarted = false;
  bool _paymentCompleted = false;
  
  // Payment states
  bool _isInitializing = false;
  bool _isVerifying = false;
  bool _checkoutOpened = false;
  String? _txRef;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoStarted) return;
      _autoStarted = true;
      _checkPaymentStatus();
    });
    
    // Listen to booking provider changes to update payment status
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.addListener(_onBookingChanged);
    
    // Initialize deep link listener for payment return
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.removeListener(_onBookingChanged);
    _appLinks = null; // Set to null instead of dispose
    super.dispose();
  }

  AppLinks? _appLinks;

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    
    // Listen for deep links
    _appLinks!.uriLinkStream.listen((uri) {
      if (uri != null && mounted) {
        _handleDeepLink(uri!);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    // Check if this is a payment return deep link
    if (uri.path.contains('/payment/chapa/callback')) {
      final txRef = uri.queryParameters['tx_ref'];
      if (txRef != null && txRef.isNotEmpty) {
        setState(() {
          _txRef = txRef;
          _checkoutOpened = true;
        });
        
        // Auto-verify payment when deep link is received
        _verifyPayment();
      }
    }
  }

  void _onBookingChanged() {
    if (widget.bookingId != null) {
      final booking = context.read<BookingProvider>().getBooking(widget.bookingId!);
      if (booking != null) {
        final wasCompleted = _paymentCompleted;
        final isCompleted = booking.status == BookingStatus.inProgress || 
                           booking.status == BookingStatus.completed;
        
        if (wasCompleted != isCompleted) {
          setState(() {
            _paymentCompleted = isCompleted;
          });
        }
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (widget.bookingId == null || widget.bookingId!.isEmpty) return;
    
    final bookingProvider = context.read<BookingProvider>();
    await bookingProvider.loadBooking(widget.bookingId!);
    
    if (!mounted) return;
    
    final booking = bookingProvider.getBooking(widget.bookingId!);
    if (booking != null) {
      // Check if booking is in a state that indicates payment is completed
      // For example, if booking is inProgress or completed, payment is likely done
      if (booking.status == BookingStatus.inProgress || 
          booking.status == BookingStatus.completed) {
        setState(() {
          _paymentCompleted = true;
        });
      }
    }
  }

  Future<void> _startPayment() async {
    if (widget.bookingId == null || widget.bookingId!.isEmpty) {
      _showSnack('Booking ID is missing.');
      return;
    }
    
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });
    
    final paymentProvider = context.read<PaymentProvider>();
    
    final initialization = await paymentProvider.initializeBookingPayment(
      bookingId: widget.bookingId!,
      amount: widget.quote.price,
      serviceRequestId: widget.request.id,
    );
    if (!mounted) return;
    
    setState(() {
      _isInitializing = false;
    });
    
    if (initialization == null) {
      setState(() {
        _errorMessage = paymentProvider.errorMessage ?? 'Failed to start payment.';
      });
      return;
    }

    // Store transaction reference for later verification
    setState(() {
      _initialization = initialization;
      _txRef = initialization.transactionReference;
    });

    // Open checkout URL in external browser
    final uri = Uri.tryParse(initialization.checkoutUrl);
    if (uri == null) {
      setState(() {
        _errorMessage = 'Invalid checkout URL.';
      });
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    
    if (!launched) {
      setState(() {
        _errorMessage = 'Unable to open checkout.';
      });
      return;
    }

    setState(() {
      _checkoutOpened = true;
    });
  }

  Future<void> _verifyPayment({bool isRetry = false}) async {
    if (_txRef == null || _txRef!.isEmpty) {
      setState(() {
        _errorMessage = 'Missing transaction reference.';
      });
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    final paymentProvider = context.read<PaymentProvider>();
    final bookingProvider = context.read<BookingProvider>();
    
    final result = await paymentProvider.verifyPayment(_txRef!);
    if (!mounted) return;
    
    setState(() {
      _isVerifying = false;
    });
    
    if (result == null || !result.verified) {
      setState(() {
        _errorMessage = paymentProvider.errorMessage ?? 'Payment verification failed.';
      });
      return;
    }

    // Refresh booking data
    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      await bookingProvider.loadBooking(widget.bookingId!);
    }

    if (!mounted) return;
    
    setState(() {
      _paymentCompleted = true;
      _checkoutOpened = false;
    });
    
    _showSnack('Payment verified successfully!');
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
            // Show appropriate UI based on payment state
            if (_paymentCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Payment Completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your payment has been successfully processed and your booking is confirmed.',
                      style: TextStyle(color: Colors.green.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Payment Failed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : () => _verifyPayment(isRetry: true),
                        icon: const Icon(Icons.refresh),
                        label: Text(_isVerifying ? 'Retrying...' : 'Retry Verification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_checkoutOpened) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.blue.shade700, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Complete Payment in Browser',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete your payment in the browser, then return to this app to verify.',
                      style: TextStyle(color: Colors.blue.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _verifyPayment,
                        icon: const Icon(Icons.verified),
                        label: Text(_isVerifying ? 'Verifying...' : 'I Have Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isInitializing || paymentProvider.isLoading) ? null : _startPayment,
                  icon: _isInitializing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment),
                  label: Text(_isInitializing ? 'Initializing...' : 'Pay Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                        builder: (_) =>
                            BookingDetailScreen(bookingId: bookingId),
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
