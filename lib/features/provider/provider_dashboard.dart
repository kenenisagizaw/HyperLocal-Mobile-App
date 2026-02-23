import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AvailableJobsPage(),
    MyQuotesPage(),
    MessagesPage(),
    ProviderProfilePage(), // <- New profile page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.blueGrey,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 22),
            elevation: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money),
                label: 'Quotes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- Available Jobs -------------------

class AvailableJobsPage extends StatelessWidget {
  const AvailableJobsPage({super.key});

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.quoted:
        return Colors.purple;
      case RequestStatus.booked:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.teal;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(RequestStatus status) {
    return status
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final requests = Provider.of<RequestProvider>(context).requests;
    final quoteProvider = Provider.of<QuoteProvider>(context);

    if (requests.isEmpty) {
      return const Center(child: Text('No available jobs'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isDisabled = req.status == RequestStatus.booked ||
            req.status == RequestStatus.inProgress ||
            req.status == RequestStatus.completed;

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${req.category} • ${req.location}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(req.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(req.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(req.description),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // ignore: sort_child_properties_last
              child: const Text('Quote'),
              onPressed: isDisabled
                  ? null
                  : () {
                      quoteProvider.addQuote(
                        Quote(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          requestId: req.id,
                          providerName: 'You',
                          price: 1500,
                          notes: 'I can do it',
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quote submitted')),
                      );
                    },
            ),
          ),
        );
      },
    );
  }
}

// ------------------- My Quotes -------------------

class MyQuotesPage extends StatelessWidget {
  const MyQuotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quotes = Provider.of<QuoteProvider>(context).quotes;

    if (quotes.isEmpty) {
      return const Center(child: Text('No quotes yet'));
    }

    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final q = quotes[index];

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              '\$${q.price}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            subtitle: Text(q.notes),
          ),
        );
      },
    );
  }
}

// ------------------- Messages -------------------

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Messages', style: TextStyle(fontSize: 18)),
    );
  }
}

// ------------------- Provider Profile -------------------

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _educationController = TextEditingController();
  final _locationController = TextEditingController();

  XFile? _profileImage;
  XFile? _nationalIdFile;
  XFile? _businessLicenseFile;
  XFile? _educationFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _businessLicenseController.dispose();
    _educationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

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

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep += 1);
    } else {
      _submitProfile();
    }
  }

  void _submitProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    authProvider.updateProviderProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      profileImage: _profileImage?.path,
      nationalId: _nationalIdController.text,
      businessLicense: _businessLicenseController.text,
      educationDoc: _educationController.text,
      location: _locationController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  Widget _buildFileButton(String label, XFile? file, String type) {
    return ElevatedButton.icon(
      onPressed: () => _pickFile(ImageSource.gallery, type),
      icon: Icon(file == null ? Icons.upload_file : Icons.check_circle, color: Colors.white),
      label: Text(file == null ? label : 'Uploaded'),
      style: ElevatedButton.styleFrom(
        backgroundColor: file == null ? Colors.blue : Colors.green,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
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
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                  child: Text(_currentStep == 1 ? 'Submit' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Basic Info'),
            content: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickFile(ImageSource.gallery, 'profile'),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField(_emailController, 'Email (optional)', Icons.email, keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          Step(
            title: const Text('Verification'),
            content: Column(
              children: [
                _buildTextField(_nationalIdController, 'National ID Number', Icons.badge),
                _buildFileButton('Upload National ID', _nationalIdFile, 'nid'),
                _buildTextField(_businessLicenseController, 'Business License Number', Icons.business),
                _buildFileButton('Upload License', _businessLicenseFile, 'business'),
                _buildTextField(_educationController, 'Educational Qualification', Icons.school),
                _buildFileButton('Upload Education Document', _educationFile, 'education'),
                _buildTextField(_locationController, 'Location', Icons.location_on),
              ],
            ),
          ),
        ],
      ),
    );
  }
}