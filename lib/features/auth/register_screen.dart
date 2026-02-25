import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import 'providers/auth_provider.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  UserRole? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            DropdownButton<UserRole>(
              value: selectedRole,
              hint: const Text('Select Role'),
              items: UserRole.values.map((role) {
                return DropdownMenuItem(value: role, child: Text(role.name));
              }).toList(),
              onChanged: (role) => setState(() => selectedRole = role),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Register'),
              onPressed: () {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    selectedRole == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final user = UserModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  role: selectedRole!,
                );

                Provider.of<AuthProvider>(context, listen: false).login(user);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => user.role == UserRole.customer
                        ? const CustomerDashboard()
                        : const ProviderDashboard(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
