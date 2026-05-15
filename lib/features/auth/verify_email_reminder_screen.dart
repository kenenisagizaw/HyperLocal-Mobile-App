import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_scaffold.dart';

class VerifyEmailReminderScreen extends StatefulWidget {
	const VerifyEmailReminderScreen({super.key});

	@override
	State<VerifyEmailReminderScreen> createState() =>
			_VerifyEmailReminderScreenState();
}

class _VerifyEmailReminderScreenState extends State<VerifyEmailReminderScreen> {
	bool _sent = false;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!mounted) {
				return;
			}
			_sendVerification();
		});
	}

	Future<void> _sendVerification() async {
		if (_sent) {
			return;
		}

		final authProvider = context.read<AuthProvider>();
		final success = await authProvider.sendEmailVerificationCode();
		if (!mounted) {
			return;
		}

		_sent = true;

		if (!success) {
			final message = authProvider.errorMessage ??
					'We could not send the verification email. Try again later.';
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(message)),
			);
			return;
		}

		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Verification email sent.')),
		);
	}

	void _goToLogin() {
		Navigator.pushReplacement(
			context,
			MaterialPageRoute(builder: (_) => const LoginScreen()),
		);
	}

	@override
	Widget build(BuildContext context) {
		return AuthScaffold(
			title: 'Verify your email',
			subtitle: 'Check your inbox and verify your email address to continue.',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const Icon(
						Icons.mark_email_unread_outlined,
						size: 64,
						color: Color(0xFF1F2A44),
					),
					const SizedBox(height: 16),
					Text(
						'We sent a verification message to your email. Please verify it, then log in to continue.',
						textAlign: TextAlign.center,
						style: GoogleFonts.dmSans(fontSize: 15, height: 1.4),
					),
					const SizedBox(height: 24),
					ElevatedButton(
						onPressed: _goToLogin,
						style: ElevatedButton.styleFrom(
							padding: const EdgeInsets.symmetric(vertical: 16),
							backgroundColor: const Color(0xFF1F2A44),
							foregroundColor: Colors.white,
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(18),
							),
						),
						child: Text(
							'Go to login',
							style: GoogleFonts.dmSans(
								fontSize: 16,
								fontWeight: FontWeight.w600,
							),
						),
					),
				],
			),
		);
	}
}
