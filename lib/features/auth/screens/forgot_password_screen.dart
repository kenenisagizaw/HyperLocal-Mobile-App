import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes.dart';
import '../providers/password_reset_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_reset_form_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<PasswordResetProvider>();
    final success = await provider.requestReset(
      email: _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? provider.lastSuccessMessage ??
                    'Check your email for reset instructions.'
              : provider.errorMessage ?? 'Unable to send reset email.',
        ),
      ),
    );

    if (success) {
      Navigator.pushNamed(context, Routes.verifyResetToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordResetProvider>();

    return AuthScaffold(
      title: 'Forgot password',
      subtitle: 'Enter your email and we will send a secure reset link.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordResetFormField(
              controller: _emailController,
              label: 'Email address',
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.mail_outline,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: provider.isLoading ? null : _submit,
              child: provider.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
      footer: Center(
        child: TextButton(
          onPressed: provider.isLoading
              ? null
              : () => Navigator.pushNamed(context, Routes.verifyResetToken),
          child: const Text('I already have a reset token'),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
