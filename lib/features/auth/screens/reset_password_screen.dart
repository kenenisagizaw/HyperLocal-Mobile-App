import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes.dart';
import '../providers/password_reset_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_reset_form_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<PasswordResetProvider>();
    final token = widget.token ?? provider.verifiedToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your reset token first.')),
      );
      Navigator.pushReplacementNamed(context, Routes.verifyResetToken);
      return;
    }

    final success = await provider.confirmReset(
      token: token,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to reset password. Try again.',
          ),
        ),
      );
      return;
    }

    _passwordController.clear();
    _confirmController.clear();
    provider.clearToken();
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.resetPasswordSuccess,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordResetProvider>();

    return AuthScaffold(
      title: 'Create new password',
      subtitle: 'Use a strong password with at least 8 characters.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordResetFormField(
              controller: _passwordController,
              label: 'New password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: 14),
            PasswordResetFormField(
              controller: _confirmController,
              label: 'Confirm password',
              prefixIcon: Icons.lock_reset,
              obscureText: _obscureConfirm,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateConfirm,
              suffixIcon: IconButton(
                tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: provider.isLoading ? null : _submit,
              child: provider.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset password'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}
