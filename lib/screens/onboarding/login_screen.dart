import 'dart:async';
import '../../services/email_otp_service.dart'; // ✅ CHANGED
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gigshield_logo.dart';
import 'otp_screen.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = ''; // ✅ CHANGED
  bool _loading = false;
  AppRole? _role;

  bool get _hasValidEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email); // ✅ CHANGED
  bool get _canContinue => _hasValidEmail && _role != null;

  void _showValidationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter a valid email and choose Worker or Insurer.'), // ✅ CHANGED
      ),
    );
  }

Future<void> _sendOtp() async {
  if (!_canContinue || _role == null) {
    _showValidationMessage();
    return;
  }

  setState(() => _loading = true);

  final prefs = await SharedPreferences.getInstance();
  final isReturning = prefs.getString('worker_json') != null;

  final success = await EmailOtpService.sendOtp(_email); // ✅ CHANGED

  if (!mounted) return;

  setState(() => _loading = false);

  if (success) {
    Navigator.push(
      context,
      CupertinoPageRoute<void>(
        builder: (_) => OtpScreen(
          email: _email, // ✅ CHANGED
          role: _role!,
          isReturningUser: isReturning,
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send OTP")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: bottomInset + 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    TealHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GigShieldLogo(size: 28, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'GigShield',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome!\nEnter your email', // ✅ CHANGED
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'to get started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: kCardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📧 EMAIL', // ✅ CHANGED
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ✅ SIMPLIFIED INPUT (kept structure)
                            TextField(
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) => setState(() => _email = value),
                              decoration: InputDecoration(
                                hintText: 'Enter email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Text(
                              'ACCOUNT ROLE',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Worker'),
                                    selected: _role == AppRole.worker,
                                    onSelected: (_) => setState(() => _role = AppRole.worker),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Insurer'),
                                    selected: _role == AppRole.insurer,
                                    onSelected: (_) => setState(() => _role = AppRole.insurer),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              label: 'Send OTP →',
                              isLoading: _loading,
                              onPressed: _canContinue ? _sendOtp : null,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'By continuing you agree to our ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSoft,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Terms & Privacy Policy',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          if (!_canContinue) {
                                            _showValidationMessage();
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute<void>(
                                              builder: (_) => const TermsScreen(),
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}