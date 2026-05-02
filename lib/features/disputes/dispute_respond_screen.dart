import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/dispute_model.dart';
import 'providers/dispute_provider.dart';

class DisputeRespondScreen extends StatefulWidget {
  const DisputeRespondScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  State<DisputeRespondScreen> createState() => _DisputeRespondScreenState();
}

class _DisputeRespondScreenState extends State<DisputeRespondScreen> {
  final _noteController = TextEditingController();
  final List<XFile> _media = [];
  DisputeDecision _decision = DisputeDecision.accept;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() {
      final remaining = 6 - _media.length;
      _media.addAll(files.take(remaining));
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _media.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<DisputeProvider>();
    final dispute = await provider.respondDispute(
      disputeId: widget.disputeId,
      decision: _decision == DisputeDecision.reject ? 'REJECT' : 'ACCEPT',
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      media: _media,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (dispute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Failed to respond to dispute.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respond to Dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<DisputeDecision>(
              value: _decision,
              items: [DisputeDecision.accept, DisputeDecision.reject]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(disputeDecisionLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _decision = value);
              },
              decoration: const InputDecoration(
                labelText: 'Decision',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Evidence (up to 6)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _media.length >= 6 ? null : _pickMedia,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_media.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _media
                    .asMap()
                    .entries
                    .map(
                      (entry) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(entry.value.path),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.black54,
                            onPressed: () => _removeMedia(entry.key),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit Response'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
