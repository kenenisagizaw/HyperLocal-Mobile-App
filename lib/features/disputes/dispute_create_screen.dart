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
  final ImagePicker _picker = ImagePicker();

  DisputeResolution _resolution = DisputeResolution.refund;

  bool _isSubmitting = false;

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
      _showSnack('Please fill in all required fields.');
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.serviceRequestTitle ?? 'Service Request';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Raise Dispute',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dispute For',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Reason',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: _reasonController,
              hint: 'Briefly explain the issue',
              icon: Icons.info_outline_rounded,
            ),

            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            _buildTextField(
              controller: _descriptionController,
              hint: 'Provide detailed explanation...',
              icon: Icons.description_outlined,
              maxLines: 5,
            ),

            const SizedBox(height: 20),

            const Text(
              'Requested Resolution',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<DisputeResolution>(
                value: _resolution,
                borderRadius: BorderRadius.circular(18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.gavel_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
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
              ),
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                const Text(
                  'Evidence',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_media.length}/6',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: _media.length >= 6 ? null : _pickMedia,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        color: theme.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload Images',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add supporting screenshots or photos',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_media.isNotEmpty) ...[
              const SizedBox(height: 18),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _media.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final file = _media[index];

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(file.path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Dispute',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}