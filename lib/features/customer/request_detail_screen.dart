import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../payments/payment_screen.dart';
import 'providers/provider_directory_provider.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.quotes,
  });

  final ServiceRequest request;
  final List<Quote> quotes;

  @override
  Widget build(BuildContext context) {
    final providerDirectory = context.watch<ProviderDirectoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.category,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(request.description),
            const SizedBox(height: 12),
            _DetailRow(label: 'Location', value: request.location),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Budget',
              value: '\$${request.budget.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 20),
            const Text(
              'Quotes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: quotes.isEmpty
                  ? const Center(child: Text('No quotes yet'))
                  : ListView.builder(
                      itemCount: quotes.length,
                      itemBuilder: (context, index) {
                        final quote = quotes[index];
                        final provider = quote.providerId == null
                            ? null
                            : providerDirectory.getProviderById(
                                quote.providerId!,
                              );
                        final providerName =
                            provider?.name ?? quote.providerName;

                        return Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              '$providerName - \$${quote.price.toStringAsFixed(2)}',
                            ),
                            subtitle: Text(quote.notes),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      request: request,
                                      quote: quote,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Accept & Pay'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
