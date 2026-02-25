import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import 'providers/auth_provider.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Login as Customer'),
              onPressed: () {
                final user = UserModel(
                  id: 'customer-1',
                  name: 'Michael Abate',
                  email: 'customer@example.com',
                  role: UserRole.customer,
                  phone: '0922 445 566',
                );
                Provider.of<AuthProvider>(context, listen: false).login(user);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerDashboard()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Login as Provider'),
              onPressed: () {
                final user = UserModel(
                  id: 'provider-1',
                  name: 'Abebe Bekele',
                  email: 'provider@example.com',
                  role: UserRole.provider,
                  phone: '0911 223 344',
                );
                Provider.of<AuthProvider>(context, listen: false).login(user);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProviderDashboard()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
