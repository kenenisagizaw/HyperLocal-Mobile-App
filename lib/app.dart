import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/models/user_model.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/customer/customer_dashboard.dart';
import 'features/provider/provider_dashboard.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyperlocal Marketplace',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: Routes.routes,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return user.role == UserRole.customer
        ? const CustomerDashboard()
        : const ProviderDashboard();
  }
}
