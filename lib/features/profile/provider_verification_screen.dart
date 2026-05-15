import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';

enum VerificationStatus { notSubmitted, pendingReview, rejected, verified }

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _idNumberController = TextEditingController();

  XFile? _idDocument;
  XFile? _idDocumentBack;
  XFile? _selfieImage;
  VerificationStatus _status = VerificationStatus.notSubmitted;
  bool _isLoading = false;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickIdDocument() async {
    if (_status != VerificationStatus.notSubmitted &&
        _status != VerificationStatus.rejected) {
      return;
    }

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
        _status != VerificationStatus.rejected) {
      return;
    }

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

  bool _isFormValid() {
    return _idDocument != null && _selfieImage != null;
  }

  Future<void> _submitVerification() async {
    if (_idNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your ID number')),
      );
      return;
    }
    if (!_isFormValid()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.uploadIdentity(
        idDocument: _idDocument!,
        idDocumentBack: _idDocumentBack,
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Your verification has been submitted for review. You will be notified once it\'s processed.',
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
    _checkVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Verification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 8,
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            title: const Text('Provider Verification'),
                            centerTitle: true,
                    children: [
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                const Text(
                                  'Upload your ID (front and back if available) and a selfie. Your request will be manually reviewed by admin.',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
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
                                          'Please upload a clear photo of your ID. Back side is optional but recommended.',
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Verification Status',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor().withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _getStatusColor()),
                                        ),
                                        child: Text(
                                          _getStatusText(),
                                          style: TextStyle(
                                            color: _getStatusColor(),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _idNumberController,
                                  enabled: _isInputEnabled(),
                                  decoration: const InputDecoration(
                                    labelText: 'ID Number',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isInputEnabled() ? _pickIdDocument : null,
                                  icon: Icon(
                                    _idDocument != null ? Icons.check_circle : Icons.upload_file,
                                  ),
                                  label: Text(
                                    _idDocument != null ? 'ID Document Uploaded' : 'Upload ID Document (Front)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _isInputEnabled() ? _pickIdDocumentBack : null,
                                  icon: Icon(
                                    _idDocumentBack != null
                                        ? Icons.check_circle
                                        : Icons.upload_file,
                                  ),
                                  label: Text(
                                    _idDocumentBack != null
                                        ? 'ID Document Back Uploaded'
                                        : 'Upload ID Document (Back, Optional)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _isInputEnabled() ? _pickSelfieImage : null,
                                  icon: Icon(
                                    _selfieImage != null ? Icons.check_circle : Icons.camera_alt,
                                  ),
                                  label: Text(
                                    _selfieImage != null ? 'Selfie Uploaded' : 'Take a Selfie',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isLoading || !_isInputEnabled()
                                      ? null
                                      : _submitVerification,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Submit Verification'),
                                ),
                              ],
                            ),
                          ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Check verification status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Submit Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
