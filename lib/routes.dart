import 'package:flutter/material.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

class Routes {
  static const roleSelect = '/';
  static const login = '/login';
  static const register = '/register';

  static Map<String, WidgetBuilder> routes = {
    roleSelect: (_) => const RoleSelectionScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
  };
}
