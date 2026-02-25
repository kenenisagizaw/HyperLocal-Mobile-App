import 'package:flutter/material.dart';

import '../../data/models/quote_model.dart';

class QuoteSentScreen extends StatelessWidget {
  const QuoteSentScreen({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Sent')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your quote has been sent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Amount: \$${quote.price.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text('Notes: ${quote.notes}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Jobs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
