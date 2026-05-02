import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/payments/connect_packages_screen.dart';
import 'features/payments/checkout_pending_screen.dart';
import 'features/payments/payment_result_screen.dart';
import 'features/payments/payment_return_handler.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyperlocal Marketplace',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case '/welcome':
            return MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case '/verify-email':
            return MaterialPageRoute(
              builder: (_) => const VerifyEmailScreen(),
            );
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case '/reset-password':
            return MaterialPageRoute(
              builder: (_) => const ResetPasswordScreen(),
            );
          case '/auth':
            return MaterialPageRoute(
              builder: (_) => const AuthGate(),
            );
          case '/connect-packages':
            return MaterialPageRoute(
              builder: (_) => const ConnectPackagesScreen(),
            );
          case '/checkout-pending':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => CheckoutPendingScreen(
                transactionReference: args?['transactionReference'],
                connectAmount: args?['connectAmount'],
                amount: args?['amount'],
              ),
            );
          case '/payment-result':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => PaymentResultScreen(
                success: args?['success'] ?? false,
                transactionReference: args?['transactionReference'],
                connectAmount: args?['connectAmount'],
                amount: args?['amount'],
                error: args?['error'],
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Route Not Found')),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64),
                      SizedBox(height: 16),
                      Text('Route not found'),
                      SizedBox(height: 8),
                      Text('Please check the route name and try again'),
                    ],
                  ),
                ),
              ),
            );
        }
      },
      builder: (context, child) {
        return PaymentReturnHandler(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
