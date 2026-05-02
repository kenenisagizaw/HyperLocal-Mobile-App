import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/dispute_model.dart';
import 'dispute_detail_screen.dart';
import 'providers/dispute_provider.dart';

class DisputeCreateScreen extends StatefulWidget {
  const DisputeCreateScreen({
    super.key,
    required this.serviceRequestId,
    this.serviceRequestTitle,
  });

  final String serviceRequestId;
  final String? serviceRequestTitle;

  @override
  State<DisputeCreateScreen> createState() => _DisputeCreateScreenState();
}

class _DisputeCreateScreenState extends State<DisputeCreateScreen> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _media = [];
  DisputeResolution _resolution = DisputeResolution.refund;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
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
    if (_reasonController.text.trim().length < 3 ||
        _descriptionController.text.trim().length < 10) {
      _showSnack('Please fill reason and description.');
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<DisputeProvider>();
    final dispute = await provider.createDispute(
      serviceRequestId: widget.serviceRequestId,
      reason: _reasonController.text.trim(),
      description: _descriptionController.text.trim(),
      requestedResolution: _resolution.name.toUpperCase(),
      media: _media,
    );
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (dispute == null) {
      _showSnack(provider.errorMessage ?? 'Failed to create dispute.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DisputeDetailScreen(disputeId: dispute.id),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.serviceRequestTitle ?? 'Service Request';

    return Scaffold(
      appBar: AppBar(title: const Text('Raise Dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DisputeResolution>(
              value: _resolution,
              items: DisputeResolution.values
                  .where((value) => value != DisputeResolution.unknown)
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(disputeResolutionLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _resolution = value);
              },
              decoration: const InputDecoration(
                labelText: 'Requested Resolution',
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
                child: Text(_isSubmitting ? 'Submitting...' : 'Submit Dispute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
