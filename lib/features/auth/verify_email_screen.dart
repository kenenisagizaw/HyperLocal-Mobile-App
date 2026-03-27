import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../customer/customer_dashboard.dart';
import '../provider/provider_dashboard.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_scaffold.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController codeController = TextEditingController();
  Timer? _timer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_cooldownSeconds > 0) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendEmailVerificationCode();

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(authProvider);
      return;
    }

    _startCooldown(60);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification code sent')));
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyEmailCode(code: code);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(authProvider);
      return;
    }

    await authProvider.loadUserProfile();
    final user = authProvider.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.role == UserRole.customer
            ? const CustomerDashboard()
            : const ProviderDashboard(),
      ),
    );
  }

  void _showError(AuthProvider authProvider) {
    final statusCode = authProvider.lastStatusCode;
    final message = switch (statusCode) {
      400 => 'Invalid or expired code',
      429 => 'Too many attempts. Please wait.',
      _ => authProvider.errorMessage ?? 'Verification failed',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'Enter the 6-digit code we sent to your inbox.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _verifyCode,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF1F2A44),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Verify & Continue',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cooldownSeconds > 0 ? null : _sendCode,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: const Color(0xFF1F2A44),
              side: const BorderSide(color: Color(0xFF1F2A44)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _cooldownSeconds > 0
                  ? 'Resend in $_cooldownSeconds s'
                  : 'Resend code',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
