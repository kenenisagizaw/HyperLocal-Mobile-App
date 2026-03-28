import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../customer/providers/provider_directory_provider.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  final _nationalIdController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _educationController = TextEditingController();

  XFile? _nationalIdFile;
  XFile? _businessLicenseFile;
  XFile? _educationFile;
  XFile? _selfieFile;

  final ImagePicker _picker = ImagePicker();
  LatLng? _providerLocation;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _businessLicenseController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      switch (type) {
        case 'nid':
          _nationalIdFile = file;
          break;
        case 'business':
          _businessLicenseFile = file;
          break;
        case 'education':
          _educationFile = file;
          break;
        case 'selfie':
          _selfieFile = file;
          break;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      await Geolocator.openAppSettings();
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      _providerLocation = LatLng(position.latitude, position.longitude);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location fetched successfully')),
    );
  }

  Future<void> _submitVerification() async {
    if (_nationalIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your ID number')),
      );
      return;
    }
    if (_nationalIdFile == null || _selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload ID and selfie to continue')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.uploadIdentity(
      idDocument: _nationalIdFile!,
      selfie: _selfieFile!,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Identity upload failed',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification submitted. We will review your documents.'),
      ),
    );

    if (_providerLocation != null) {
      final providerDirectory = Provider.of<ProviderDirectoryProvider>(
        context,
        listen: false,
      );
      authProvider.updateProviderVerification(
        nationalId: _nationalIdController.text.trim(),
        businessLicense: _businessLicenseController.text.trim(),
        educationDoc: _educationController.text.trim(),
        location:
            '${_providerLocation!.latitude},${_providerLocation!.longitude}',
        latitude: _providerLocation!.latitude,
        longitude: _providerLocation!.longitude,
        isVerified: false,
      );

      final updatedProvider = authProvider.currentUser;
      if (updatedProvider != null) {
        providerDirectory.upsertProvider(updatedProvider);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _checkStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getIdentityStatus();

    if (!mounted) {
      return;
    }

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Unable to check status',
          ),
        ),
      );
      return;
    }

    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final status = data['status']?.toString() ?? 'pending';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification status: $status')),
    );
  }

  Widget _buildFileButton(String label, XFile? file, String type) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        onPressed: () => _pickFile(type),
        icon: Icon(
          file == null ? Icons.upload_file : Icons.check_circle,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          file == null ? label : 'Uploaded',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: file == null ? Colors.blue : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        _nationalIdController,
                        'National ID Number',
                        Icons.badge,
                      ),
                      _buildFileButton(
                        'Upload National ID',
                        _nationalIdFile,
                        'nid',
                      ),
                      _buildFileButton(
                        'Upload Selfie',
                        _selfieFile,
                        'selfie',
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _businessLicenseController,
                        'Business License Number',
                        Icons.business,
                      ),
                      _buildFileButton(
                        'Upload License',
                        _businessLicenseFile,
                        'business',
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _educationController,
                        'Educational Qualification',
                        Icons.school,
                      ),
                      _buildFileButton(
                        'Upload Education Document',
                        _educationFile,
                        'education',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: Icon(
                          _providerLocation == null
                              ? Icons.location_on
                              : Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          _providerLocation == null
                              ? 'Use Current Location'
                              : 'Location Selected',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _providerLocation == null
                              ? Colors.blue
                              : Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_providerLocation != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                            color: Colors.blue.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_providerLocation!.latitude.toStringAsFixed(5)}, '
                                  '${_providerLocation!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _checkStatus,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
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
