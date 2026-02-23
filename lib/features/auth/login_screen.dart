import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () {
                // Mock login based on email
                final isCustomer = emailController.text.contains('customer');
                final user = UserModel(
                  id: '1',
                  name: isCustomer ? 'Kenenisa' : 'Abebe',
                  email: emailController.text,
                  phone:
                      '0000000000', // Add a mock phone number or get from input
                  role: isCustomer ? UserRole.customer : UserRole.provider,
                );
                Provider.of<AuthProvider>(context, listen: false).login(user);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isCustomer
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
