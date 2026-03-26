import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  void _submitVerification() {
    if (_providerLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your location')),
      );
      return;
    }
    if (_nationalIdController.text.trim().isEmpty ||
        _businessLicenseController.text.trim().isEmpty ||
        _educationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete verification details')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      isVerified: true,
    );

    final updatedProvider = authProvider.currentUser;
    if (updatedProvider != null) {
      providerDirectory.upsertProvider(updatedProvider);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification submitted. We will review your documents.'),
      ),
    );

    Navigator.pop(context);
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
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: _providerLocation!,
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags:
                                      InteractiveFlag.pinchZoom |
                                      InteractiveFlag.drag,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.my_first_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _providerLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
