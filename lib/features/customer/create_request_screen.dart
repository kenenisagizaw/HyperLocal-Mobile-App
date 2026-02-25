import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/request_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_textfield.dart';
import 'my_requests_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();
  double? _locationLat;
  double? _locationLng;

  String? _selectedCategory;
  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Painting',
    'Carpentry',
    'Cleaning',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() {
      _photos.addAll(files);
    });
  }

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (!mounted) return;
    setState(() {
      _locationLat = position.latitude;
      _locationLng = position.longitude;
      _locationController.text =
          '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location captured')));
  }

  Future<void> _submit(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final requestProvider = context.read<RequestProvider>();
    final navigator = Navigator.of(context);

    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first.')));
      return;
    }

    if (user.role != UserRole.customer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only customers can create requests.')),
      );
      return;
    }

    if (_selectedCategory == null ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim());
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget.')),
      );
      return;
    }

    final request = ServiceRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: user.id,
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      location: _locationController.text.trim(),
      locationLat: _locationLat,
      locationLng: _locationLng,
      budget: budget,
      photoPaths: _photos.map((file) => file.path).toList(),
      createdAt: DateTime.now(),
      status: RequestStatus.pending,
    );

    await requestProvider.createRequest(request);

    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RequestProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CustomTextField(controller: _locationController, label: 'Location'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _budgetController,
              label: 'Budget',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Add Photos'),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_photos.length} selected'),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _photos
                    .map(
                      (file) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            CustomButton(
              text: isLoading ? 'Submitting...' : 'Submit Request',
              onPressed: isLoading ? () {} : () => _submit(context),
            ),
          ],
        ),
      ),
    );
  }
}
