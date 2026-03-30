import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../customer/providers/provider_directory_provider.dart';
import 'provider_verification_screen.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  bool _isEditing = false;
  bool _isLoggingOut = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  // Files
  XFile? _profileImage;
  List<XFile> _portfolioImages = [];
  List<PlatformFile> _certificationFiles = [];

  final ImagePicker _picker = ImagePicker();

  // Location
  LatLng? _providerLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
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
        if (type == 'profile') {
          _profileImage = file;
        }
      });
    }
  }

  Future<void> _pickPortfolioImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _portfolioImages = files;
      });
    }
  }

  Future<void> _pickCertifications() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (result == null) {
      return;
    }

    setState(() {
      _certificationFiles = result.files
          .where((file) => file.path != null)
          .toList();
    });
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
  Future<bool> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final providerDirectory = Provider.of<ProviderDirectoryProvider>(
      context,
      listen: false,
    );

    final userSuccess = await authProvider.updateUserProfile(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      bio: _bioController.text,
      avatarFile: _profileImage,
    );

    if (!userSuccess) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Profile update failed'),
        ),
      );
      return false;
    }

    if (_providerLocation != null) {
      // location handled below if provider update is needed
    }

    final portfolioUrls = <String>[];
    for (final file in _portfolioImages) {
      final path = await authProvider.uploadPortfolio(file);
      if (path == null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Portfolio upload failed',
            ),
          ),
        );
        return false;
      }
      portfolioUrls.add(path);
    }

    final certificationUrls = <String>[];
    for (final file in _certificationFiles) {
      final pathValue = file.path;
      if (pathValue == null) {
        continue;
      }
      final path = await authProvider.uploadCertification(XFile(pathValue));
      if (path == null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Certification upload failed',
            ),
          ),
        );
        return false;
      }
      certificationUrls.add(path);
    }

    final needsProviderUpdate =
        _providerLocation != null ||
        portfolioUrls.isNotEmpty ||
        certificationUrls.isNotEmpty;

    if (needsProviderUpdate) {
      final providerSuccess = await authProvider.updateProviderProfileRemote(
        latitude: _providerLocation?.latitude,
        longitude: _providerLocation?.longitude,
        portfolioUrls: portfolioUrls.isNotEmpty ? portfolioUrls : null,
        certificationsUrls: certificationUrls.isNotEmpty
            ? certificationUrls
            : null,
      );
      if (!providerSuccess) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Provider profile update failed',
            ),
          ),
        );
        return false;
      }
    }

    final updatedProvider = authProvider.currentUser;
    if (updatedProvider != null) {
      providerDirectory.upsertProvider(updatedProvider);
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    return true;
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoggingOut = true);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  // ---------------- UI helpers ----------------

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        readOnly: !enabled,
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
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (_isEditing) {
                final success = await _updateProfile();
                if (success) {
                  setState(() => _isEditing = false);
                }
                return;
              }
              setState(() => _isEditing = true);
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(
              _isEditing ? 'Done' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProviderVerificationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.verified, color: Colors.white),
            label: const Text(
              'Verify',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: Text(
              _isLoggingOut ? 'Logging out' : 'Logout',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
          currentStep: 0,
          onStepContinue: null,
          onStepCancel: null,
          connectorColor: WidgetStateProperty.all(Colors.blue.shade300),
          stepIconBuilder: (stepIndex, stepState) {
            if (stepState == StepState.complete) {
              return const Icon(Icons.check, color: Colors.green);
            }
            return null;
          },
          controlsBuilder: (context, details) {
            return const SizedBox.shrink();
          },
          steps: [
            // -------- Step 1: Basic Info --------
            Step(
              title: Text(
                'Basic Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
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
                      onTap: _isEditing
                          ? () => _pickFile(ImageSource.gallery, 'profile')
                          : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _profileImage != null
                                ? FileImage(File(_profileImage!.path))
                                : null,
                            child: _profileImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.blue.shade700,
                                  )
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                    _buildTextField(
                      _nameController,
                      'Full Name',
                      Icons.person,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      _emailController,
                      'Email (optional)',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: _isEditing,
                    ),
                    _buildTextField(
                      _bioController,
                      'Bio / Profession',
                      Icons.badge,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Portfolio Images',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          TextButton.icon(
                            onPressed: _pickPortfolioImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    if (_portfolioImages.isEmpty)
                      Text(
                        _isEditing
                            ? 'No portfolio images selected'
                            : 'No portfolio images',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _portfolioImages
                            .map(
                              (file) => Chip(
                                label: Text(file.name),
                                avatar: const Icon(Icons.image, size: 18),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Certifications (PDF)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          TextButton.icon(
                            onPressed: _pickCertifications,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    if (_certificationFiles.isEmpty)
                      Text(
                        _isEditing
                            ? 'No certifications selected'
                            : 'No certifications',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _certificationFiles
                            .map(
                              (file) => Chip(
                                label: Text(file.name),
                                avatar: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                ),
                              ),
                            )
                            .toList(),
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
