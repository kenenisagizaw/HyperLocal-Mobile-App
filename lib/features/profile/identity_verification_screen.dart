import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

enum VerificationStatus { notSubmitted, pendingReview, rejected, verified }

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _idDocument;
  File? _selfieImage;
  VerificationStatus _status = VerificationStatus.notSubmitted;
  bool _isLoading = false;

  // Permission handling
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
      // For older versions, use READ_EXTERNAL_STORAGE
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        return true;
      }
      
      // Fallback to storage permission for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else {
      // iOS
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
  }

  // Image picker methods
  Future<void> _pickIdDocument() async {
    if (_status != VerificationStatus.notSubmitted && _status != VerificationStatus.rejected) return;
    
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      _showPermissionDialog('Gallery Permission Required', 
        'Gallery permission is required to select images. Please enable it in app settings.');
      return;
    }

    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _idDocument = File(file.path);
      });
    }
  }

  Future<void> _pickSelfieImage() async {
    if (_status != VerificationStatus.notSubmitted && _status != VerificationStatus.rejected) return;
    
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showPermissionDialog('Camera Permission Required', 
        'Camera permission is required to take a selfie. Please enable it in app settings.');
      return;
    }

    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        _selfieImage = File(file.path);
      });
    }
  }

  // Form validation
  bool _isFormValid() {
    return _idDocument != null && _selfieImage != null;
  }

  // API submission
  Future<void> _submitVerification() async {
    if (!_isFormValid()) return;

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'idDocument': await MultipartFile.fromFile(_idDocument!.path, filename: 'id_document.jpg'),
        'selfie': await MultipartFile.fromFile(_selfieImage!.path, filename: 'selfie.jpg'),
      });

      final response = await dio.post(
        'https://your-api-endpoint.com/api/auth/identity/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _status = VerificationStatus.pendingReview;
        });
        _showSuccessDialog();
        // Check status after successful upload
        _checkVerificationStatus();
      } else {
        _showErrorDialog('Submission Failed', 'Please try again later.');
      }
    } catch (e) {
      _showErrorDialog('Network Error', 'Failed to submit verification. Please check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check verification status
  Future<void> _checkVerificationStatus() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://your-api-endpoint.com/api/auth/identity/status',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final statusString = data['identityStatus'] as String?;
        
        if (statusString != null) {
          setState(() {
            switch (statusString) {
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
        }
      }
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
        content: const Text('Your identity verification has been submitted for review. You will be notified once it\'s processed.'),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open app settings
              await openAppSettings();
            },
            child: const Text('Open Settings'),
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
    return _status == VerificationStatus.notSubmitted || _status == VerificationStatus.rejected;
  }

  @override
  void initState() {
    super.initState();
    // Check current status when screen loads
    _checkVerificationStatus();
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
                'Upload both sides of your National ID and a selfie. Your request will be manually reviewed by admin.',
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
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please upload a single ID document (front and back combined if needed)',
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
              
              // ID Document
              const Text(
                'ID Document',
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
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
