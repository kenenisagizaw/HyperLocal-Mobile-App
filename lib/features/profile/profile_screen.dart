import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/auth_provider.dart';

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
    _nationalIdController.dispose();
    _businessLicenseController.dispose();
    _educationController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _providerLocation = LatLng(position.latitude, position.longitude);
    });

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

    authProvider.updateProviderProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      profileImage: _profileImage?.path,
      nationalId: _nationalIdController.text,
      businessLicense: _businessLicenseController.text,
      educationDoc: _educationController.text,
      location:
          '${_providerLocation!.latitude},${_providerLocation!.longitude}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  // ---------------- UI helpers ----------------
  Widget _buildFileButton(String label, XFile? file, String type) {
    return ElevatedButton.icon(
      onPressed: () => _pickFile(ImageSource.gallery, type),
      icon: Icon(file == null ? Icons.upload_file : Icons.check_circle,
          color: Colors.white),
      label: Text(file == null ? label : 'Uploaded'),
      style: ElevatedButton.styleFrom(
        backgroundColor: file == null ? Colors.blue : Colors.green,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                  child: Text(_currentStep == 1 ? 'Submit' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style:
                        OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          // -------- Step 1: Basic Info --------
          Step(
            title: const Text('Basic Info'),
            content: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickFile(ImageSource.gallery, 'profile'),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!.path))
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                    keyboardType: TextInputType.phone),
                _buildTextField(_emailController, 'Email (optional)', Icons.email,
                    keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          // -------- Step 2: Verification --------
          Step(
            title: const Text('Verification'),
            content: Column(
              children: [
                _buildTextField(
                    _nationalIdController, 'National ID Number', Icons.badge),
                _buildFileButton('Upload National ID', _nationalIdFile, 'nid'),
                _buildTextField(_businessLicenseController,
                    'Business License Number', Icons.business),
                _buildFileButton(
                    'Upload License', _businessLicenseFile, 'business'),
                _buildTextField(
                    _educationController, 'Educational Qualification', Icons.school),
                _buildFileButton(
                    'Upload Education Document', _educationFile, 'education'),
                const SizedBox(height: 12),
                // -------- GPS Location Button --------
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(
                      _providerLocation == null
                          ? Icons.location_on
                          : Icons.check,
                      color: Colors.white),
                  label: Text(_providerLocation == null
                      ? 'Use Current Location'
                      : 'Location Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _providerLocation == null ? Colors.blue : Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 12),
                // Optional: Map Preview
                if (_providerLocation != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _providerLocation!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('provider-location'),
                          position: _providerLocation!,
                        ),
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}