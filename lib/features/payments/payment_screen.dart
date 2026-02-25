import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../auth/providers/auth_provider.dart';
import '../customer/providers/request_provider.dart';
import '../reviews/review_screen.dart';
import 'providers/payment_provider.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.request,
    required this.quote,
  });

  final ServiceRequest request;
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final currentUser = authProvider.currentUser;

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
            _SummaryRow(label: 'Service', value: request.category),
            _SummaryRow(label: 'Provider', value: quote.providerName),
            _SummaryRow(
              label: 'Total',
              value: '\$${quote.price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: currentUser == null
                    ? null
                    : () {
                        final payment = paymentProvider.createPayment(
                          requestId: request.id,
                          quoteId: quote.id,
                          payerId: currentUser.id,
                          amount: quote.price,
                        );
                        requestProvider.updateStatus(
                          request.id,
                          RequestStatus.accepted,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentSuccessScreen(
                              payment: payment,
                              request: request,
                              quote: quote,
                            ),
                          ),
                        );
                      },
                child: const Text('Pay Now'),
              ),
            ),
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
  });

  final Payment payment;
  final ServiceRequest request;
  final Quote quote;

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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: quote.providerId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              request: request,
                              providerId: quote.providerId!,
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
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
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
