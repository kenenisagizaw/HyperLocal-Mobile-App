import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';

enum VerificationStatus { notSubmitted, pendingReview, rejected, verified }

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _idNumberController = TextEditingController();

  XFile? _idDocument;
  XFile? _idDocumentBack;
  XFile? _selfieImage;
  VerificationStatus _status = VerificationStatus.notSubmitted;
  bool _isLoading = false;

  // Image picker methods
  Future<void> _pickIdDocument() async {
    if (_status != VerificationStatus.notSubmitted &&
        _status != VerificationStatus.rejected)
      return;

    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _idDocument = file);
      }
    } catch (e) {
      _showPermissionDialog(
        'Gallery Access Required',
        'Unable to access gallery. Please allow gallery/photos access in your device settings.',
      );
    }
  }

  Future<void> _pickIdDocumentBack() async {
    if (_status != VerificationStatus.notSubmitted &&
        _status != VerificationStatus.rejected) {
      return;
    }

    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _idDocumentBack = file);
      }
    } catch (e) {
      _showPermissionDialog(
        'Gallery Access Required',
        'Unable to access gallery. Please allow gallery/photos access in your device settings.',
      );
    }
  }

  Future<void> _pickSelfieImage() async {
    if (_status != VerificationStatus.notSubmitted &&
        _status != VerificationStatus.rejected)
      return;

    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        setState(() => _selfieImage = file);
      }
    } catch (e) {
      _showPermissionDialog(
        'Camera Access Required',
        'Unable to access camera. Please allow camera access in your device settings.',
      );
    }
  }

  // Form validation
  bool _isFormValid() {
    return _idNumberController.text.trim().isNotEmpty &&
        _idDocument != null &&
        _idDocumentBack != null &&
        _selfieImage != null;
  }

  // API submission
  Future<void> _submitVerification() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide National ID FAN number, front and back images, and a selfie.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ...existing code...
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.uploadIdentity(
        idDocument: _idDocument!,
        idDocumentBack: _idDocumentBack!,
        selfie: _selfieImage!,
        idNumber: _idNumberController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        setState(() => _status = VerificationStatus.pendingReview);
        _showSuccessDialog();
        await _checkVerificationStatus();
      } else {
        _showErrorDialog(
          'Submission Failed',
          authProvider.errorMessage ?? 'Please try again later.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Check verification status
  Future<void> _checkVerificationStatus() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await authProvider.getIdentityStatus();
      if (!mounted || response == null) return;

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final statusString = data['identityStatus'] ?? data['status'];
      if (statusString is! String) return;

      setState(() {
        switch (statusString.toUpperCase()) {
          case 'NOT_SUBMITTED':
            _status = VerificationStatus.notSubmitted;
            break;
          case 'PENDING_REVIEW':
            _status = VerificationStatus.pendingReview;
            break;
          case 'REJECTED':
            _status = VerificationStatus.rejected;
            break;
          case 'VERIFIED':
            _status = VerificationStatus.verified;
            break;
        }
      });
    } catch (e) {
      // Silent fail for status check
    }
  }

  // Dialog methods
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Your identity verification has been submitted for review. You will be notified once it\'s processed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Status color and text
  Color _getStatusColor() {
    switch (_status) {
      case VerificationStatus.notSubmitted:
        return Colors.orange;
      case VerificationStatus.pendingReview:
        return Colors.blue;
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case VerificationStatus.notSubmitted:
        return 'NOT_SUBMITTED';
      case VerificationStatus.pendingReview:
        return 'PENDING_REVIEW';
      case VerificationStatus.verified:
        return 'VERIFIED';
      case VerificationStatus.rejected:
        return 'REJECTED';
    }
  }

  bool _isInputEnabled() {
    return _status == VerificationStatus.notSubmitted ||
        _status == VerificationStatus.rejected;
  }

  @override
  void initState() {
    super.initState();
    // Check current status when screen loads
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Identity Verification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Upload your National ID (front and back) and a selfie. Your request will be manually reviewed by admin.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Note about ID document
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please upload clear photos of your National ID (front and back).',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'CURRENT STATUS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ID Number
            const Text(
              'National ID FAN Number',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idNumberController,
              enabled: _isInputEnabled(),
              decoration: InputDecoration(
                hintText: 'Enter National ID FAN number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ID Document (Front)
            const Text(
              'National ID (Front)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildImagePicker(
              label: 'Choose File',
              fileName: _idDocument?.path.split('/').last ?? 'No file chosen',
              onTap: _pickIdDocument,
              isEnabled: _isInputEnabled(),
            ),
            const SizedBox(height: 20),

            // ID Document (Back)
            const Text(
              'National ID (Back)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildImagePicker(
              label: 'Choose File',
              fileName:
                  _idDocumentBack?.path.split('/').last ?? 'No file chosen',
              onTap: _pickIdDocumentBack,
              isEnabled: _isInputEnabled(),
            ),
            const SizedBox(height: 20),

            // Selfie Photo
            const Text(
              'Selfie Photo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildImagePicker(
              label: 'Open Camera',
              fileName: _selfieImage?.path.split('/').last ?? 'No file chosen',
              onTap: _pickSelfieImage,
              isEnabled: _isInputEnabled(),
            ),
            const SizedBox(height: 40),

            // Submit Button
            ElevatedButton(
              onPressed: (_isInputEnabled() && _isFormValid() && !_isLoading)
                  ? _submitVerification
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'SUBMIT REQUEST',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required String fileName,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.image,
              color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  color: fileName == 'No file chosen'
                      ? Colors.grey.shade500
                      : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            if (isEnabled)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
