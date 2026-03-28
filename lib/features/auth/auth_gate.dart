import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';
import 'providers/auth_provider.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    return user.role == UserRole.customer
        ? const CustomerDashboard()
        : const ProviderDashboard();
  }
}
