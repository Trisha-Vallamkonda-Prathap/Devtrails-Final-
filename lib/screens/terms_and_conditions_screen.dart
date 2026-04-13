import 'package:flutter/material.dart';
import 'package:gigshield/screens/onboarding/login_screen.dart';
import 'package:gigshield/theme/app_colors.dart';
import 'package:gigshield/widgets/gradient_button.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Please read these terms and conditions carefully before using the GigShield application.\n\n'
                    'By using this app, you signify your assent to these Terms and Conditions. If you do not agree to all of these Terms and Conditions, do not use this app!\n\n'
                    '1. Your agreement to these terms and conditions means you agree to pay a weekly premium for your selected risk plan.\n'
                    '2. Payouts are triggered based on predefined weather and risk conditions in your selected zone.\n'
                    '3. GigShield is not responsible for any loss of income due to factors not covered by your selected plan.\n'
                    '4. We reserve the right to modify these terms and conditions at any time. We will inform you of any changes.\n\n'
                    'By clicking "Agree and Continue", you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                    style: TextStyle(fontSize: 16, color: AppColors.textMid),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Agree and Continue',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
