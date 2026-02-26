import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';
import 'providers/auth_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handyman,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Welcome Text
                  Text(
                    'Welcome to HandyFix',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [Colors.blue.shade800, Colors.green.shade800],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose how you want to continue',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 50),

                  // Customer Card
                  _buildRoleCard(
                    context,
                    title: 'Customer',
                    subtitle: 'Book services & track orders',
                    icon: Icons.person_outline,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    onTap: () {
                      final user = UserModel(
                        id: 'customer-1',
                        name: 'Michael Abate',
                        email: 'customer@example.com',
                        role: UserRole.customer,
                        phone: '0922 445 566',
                      );
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).login(user);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerDashboard(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Provider Card
                  _buildRoleCard(
                    context,
                    title: 'Service Provider',
                    subtitle: 'Manage your services & earnings',
                    icon: Icons.build,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    onTap: () {
                      final user = UserModel(
                        id: 'provider-1',
                        name: 'Abebe Bekele',
                        email: 'provider@example.com',
                        role: UserRole.provider,
                        phone: '0911 223 344',
                      );
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).login(user);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProviderDashboard(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Footer Text
                  Text(
                    'Your trusted service partner',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: title == 'Customer'
                  ? Colors.blue.shade200
                  : Colors.green.shade200,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
