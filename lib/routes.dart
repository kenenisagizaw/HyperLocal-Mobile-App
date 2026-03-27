import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/auth/welcome_screen.dart';

class Routes {
  static const root = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> routes = {
    root: (_) => const SplashScreen(),
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    verifyEmail: (_) => const VerifyEmailScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    '/auth': (_) => const AuthGate(),
  };
}
