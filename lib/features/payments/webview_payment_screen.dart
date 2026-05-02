import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../bookings/providers/booking_provider.dart';
import 'providers/payment_provider.dart';

class WebViewPaymentScreen extends StatefulWidget {
  const WebViewPaymentScreen({
    super.key,
    required this.request,
    required this.quote,
    required this.bookingId,
    required this.checkoutUrl,
  });

  final ServiceRequest request;
  final Quote quote;
  final String bookingId;
  final String checkoutUrl;

  @override
  State<WebViewPaymentScreen> createState() => _WebViewPaymentScreenState();
}

class _WebViewPaymentScreenState extends State<WebViewPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  String? _txRef;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check if navigation is to our payment return URL
            if (request.url.contains(ApiConstants.paymentReturnUrl) || 
                request.url.contains('/payment/return')) {
              _handlePaymentReturn(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handlePaymentReturn(String returnUrl) {
    // Extract txRef from return URL
    final uri = Uri.parse(returnUrl);
    _txRef = uri.queryParameters['txRef'];
    
    setState(() {
      _paymentCompleted = true;
      _isLoading = false;
    });

    // Close WebView and verify payment
    Navigator.of(context).pop();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    if (_txRef == null) return;
    
    final paymentProvider = context.read<PaymentProvider>();
    final bookingProvider = context.read<BookingProvider>();
    
    final result = await paymentProvider.verifyPayment(_txRef!);
    
    if (!mounted) return;
    
    if (result == null || !result.verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Refresh booking data
    await bookingProvider.loadBooking(widget.bookingId);
    
    if (!mounted) return;
    
    // Show comprehensive payment success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Payment successful! Your booking is confirmed.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View Booking',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to booking details
            Navigator.of(context).pushReplacementNamed('/bookings/${widget.bookingId}');
          },
        ),
      ),
    );
    
    // Also show a dialog for better visibility
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your payment has been successfully processed.'),
            const SizedBox(height: 8),
            Text('Transaction Reference: ${_txRef}'),
            const SizedBox(height: 8),
            Text('Amount: \$${widget.quote.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('Your booking has been confirmed and you can view the details.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacementNamed('/bookings/${widget.bookingId}');
            },
            child: const Text('View Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
