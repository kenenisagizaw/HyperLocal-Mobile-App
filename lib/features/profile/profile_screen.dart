import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../customer/providers/provider_directory_provider.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  int _currentStep = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _educationController = TextEditingController();

  // Files
  XFile? _profileImage;
  XFile? _nationalIdFile;
  XFile? _businessLicenseFile;
  XFile? _educationFile;

  final ImagePicker _picker = ImagePicker();

  // Location
  LatLng? _providerLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _nationalIdController.dispose();
    _businessLicenseController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) {
        return;
      }
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email ?? '';
      _bioController.text = user.bio ?? '';
    });
  }

  // ---------------- File picker ----------------
  Future<void> _pickFile(ImageSource source, String type) async {
    final file = await _picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        switch (type) {
          case 'profile':
            _profileImage = file;
            break;
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
  }

  // ---------------- Location picker ----------------
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ignore: use_build_context_synchronously
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      await Geolocator.openAppSettings();
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _providerLocation = LatLng(position.latitude, position.longitude);
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location fetched successfully')),
    );
  }

  // ---------------- Stepper navigation ----------------
  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep += 1);
    } else {
      _submitProfile();
    }
  }

  void _submitProfile() {
    if (_providerLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your location')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final providerDirectory =
      Provider.of<ProviderDirectoryProvider>(context, listen: false);

    authProvider.updateProviderProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      bio: _bioController.text,
      profileImage: _profileImage?.path,
      nationalId: _nationalIdController.text,
      businessLicense: _businessLicenseController.text,
      educationDoc: _educationController.text,
      location:
          '${_providerLocation!.latitude},${_providerLocation!.longitude}',
      latitude: _providerLocation!.latitude,
      longitude: _providerLocation!.longitude,
    );

    final updatedProvider = authProvider.currentUser;
    if (updatedProvider != null) {
      providerDirectory.upsertProvider(updatedProvider);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  // ---------------- UI helpers ----------------
  Widget _buildFileButton(String label, XFile? file, String type) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () => _pickFile(ImageSource.gallery, type),
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
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Provider Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          connectorColor: WidgetStateProperty.all(Colors.blue.shade300),
          stepIconBuilder: (stepIndex, stepState) {
            if (stepState == StepState.complete) {
              return const Icon(Icons.check, color: Colors.green);
            }
            return null;
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        _currentStep == 1 ? 'Submit' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.blue, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            // -------- Step 1: Basic Info --------
            Step(
              title: Text(
                'Basic Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _currentStep >= 0 ? Colors.blue : Colors.grey,
                ),
              ),
              content: Container(
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
                    GestureDetector(
                      onTap: () => _pickFile(ImageSource.gallery, 'profile'),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _profileImage != null
                                ? FileImage(File(_profileImage!.path))
                                : null,
                            child: _profileImage == null
                                ? Icon(Icons.person, size: 50, color: Colors.blue.shade700)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      _emailController,
                      'Email (optional)',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      _bioController,
                      'Bio / Profession',
                      Icons.badge,
                    ),
                  ],
                ),
              ),
            ),
            // -------- Step 2: Verification --------
            Step(
              title: Text(
                'Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _currentStep >= 1 ? Colors.green : Colors.grey,
                ),
              ),
              content: Container(
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
                    _buildFileButton('Upload National ID', _nationalIdFile, 'nid'),
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
                    // -------- GPS Location Button --------
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: Icon(
                          _providerLocation == null ? Icons.location_on : Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          _providerLocation == null
                              ? 'Use Current Location'
                              : 'Location Selected',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                    ),
                    const SizedBox(height: 12),
                    // Optional: Map Preview
                    if (_providerLocation != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200, width: 2),
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
                                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.my_first_app',
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
            ),
          ],
        ),
      ),
    );
  }
}