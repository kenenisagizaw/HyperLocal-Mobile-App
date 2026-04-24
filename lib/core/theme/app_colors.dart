
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color deepBlue = Color(0xFF1A237E);
  static const Color deepGreen = Color(0xFF1B5E20);
  
  // Secondary colors
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color lightGreen = Color(0xFF66BB6A);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;
  
  // Status colors
  static const Color pending = Color(0xFFFFA726);
  static const Color confirmed = deepBlue;
  static const Color inProgress = lightBlue;
  static const Color completed = deepGreen;
  static const Color cancelled = Color(0xFFEF5350);
  
  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Error colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = deepGreen;
  static const Color warning = pending;
}