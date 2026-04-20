import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'widgets/auth_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Deep Green & Deep Blue Color Palette
    const deepGreen = Color(0xFF0D5C3E);      // Rich forest green
    const deepBlue = Color(0xFF1B3A5C);       // Deep ocean blue
    const lightGreen = Color(0xFFE8F3F0);     // Soft mint background
    const accentGreen = Color(0xFF2E7D64);    // Vibrant green accent
    const accentBlue = Color(0xFF2C5F8A);     // Vibrant blue accent
    const textDark = Color(0xFF1A2A3A);       // Dark text color
    const textMedium = Color(0xFF4A5B6E);     // Medium text color
    const textLight = Color(0xFF7A8B9F);      // Light text color

    return AuthScaffold(
      title: 'HyperLocal',
      subtitle: 'Skilled help, trusted neighbors, one tap away.',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card - Deep Green Theme
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  deepGreen.withOpacity(0.08),
                  deepBlue.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: deepGreen.withOpacity(0.15),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [deepGreen, accentGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.rocket_launch_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Get Started',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: deepGreen,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account to find services or offer your skills.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.4,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Login Button - Deep Green
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [deepGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log In',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create Account Button - Deep Blue Outline
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: deepBlue,
              side: BorderSide(color: deepBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Create Account',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'By continuing, you agree to our Terms of Service & Privacy Policy',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.4,
              color: textLight,
            ),
          ),
        ),
      ),
    );
  }
}