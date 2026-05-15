import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes.dart';
import '../providers/password_reset_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_reset_form_field.dart';

class VerifyResetTokenScreen extends StatefulWidget {
  const VerifyResetTokenScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<VerifyResetTokenScreen> createState() => _VerifyResetTokenScreenState();
}

class _VerifyResetTokenScreenState extends State<VerifyResetTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _autoVerifying = false;

  @override
  void initState() {
    super.initState();
    final token = widget.initialToken;
    if (token != null && token.isNotEmpty) {
      _tokenController.text = token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _verify(auto: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify({bool auto = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _autoVerifying = auto);
    final provider = context.read<PasswordResetProvider>();
    final success = await provider.verifyToken(token: _tokenController.text);
    if (mounted) {
      setState(() => _autoVerifying = false);
    }

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'This reset token is invalid or expired.',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      Routes.resetPassword,
      arguments: {'token': _tokenController.text.trim()},
    );
  }

  Future<void> _resend() async {
    final provider = context.read<PasswordResetProvider>();
    final success = await provider.resendReset();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? provider.lastSuccessMessage ?? 'Reset email sent.'
              : provider.errorMessage ?? 'Enter your email again to resend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordResetProvider>();
    final isBusy = provider.isLoading || _autoVerifying;

    return AuthScaffold(
      title: 'Verify reset token',
      subtitle: 'Paste the token from your email to continue.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordResetFormField(
              controller: _tokenController,
              label: 'Reset token',
              prefixIcon: Icons.key_outlined,
              textInputAction: TextInputAction.done,
              enabled: !isBusy,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Token is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isBusy ? null : _verify,
              child: isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify token'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: provider.canResend && !isBusy ? _resend : null,
              icon: const Icon(Icons.refresh),
              label: Text(
                provider.resendSecondsRemaining > 0
                    ? 'Resend in ${provider.resendSecondsRemaining}s'
                    : 'Resend email',
              ),
            ),
          ],
        ),
      ),
      footer: Center(
        child: TextButton(
          onPressed: isBusy
              ? null
              : () => Navigator.pushReplacementNamed(
                    context,
                    Routes.forgotPassword,
                  ),
          child: const Text('Use a different email'),
        ),
      ),
    );
  }
}
