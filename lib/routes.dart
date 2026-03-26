import 'package:flutter/material.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';

class Routes {
  static const login = '/login';
  static const register = '/register';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
  };
}
