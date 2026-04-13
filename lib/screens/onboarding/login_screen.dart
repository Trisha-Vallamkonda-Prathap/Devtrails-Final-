import 'dart:async';

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
  String _phone = '';
  bool _loading = false;
  AppRole? _role;

  bool get _hasValidPhone => RegExp(r'^\d{10}$').hasMatch(_phone);
  bool get _canContinue => _hasValidPhone && _role != null;

  void _showValidationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter a valid 10-digit phone number and choose Worker or Insurer.'),
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

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    Navigator.push(
      context,
      CupertinoPageRoute<void>(
        builder: (_) => OtpScreen(
          phone: _phone,
          role: _role!,
          isReturningUser: isReturning,
        ),
      ),
    );
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
                            'Welcome!\nEnter your mobile number',
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
                              '📱 MOBILE NUMBER',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.tealLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '+91',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    maxLength: 10,
                                    keyboardType: TextInputType.phone,
                                    buildCounter: (
                                      BuildContext _, {
                                      required int currentLength,
                                      required bool isFocused,
                                      required int? maxLength,
                                    }) {
                                      return null;
                                    },
                                    onChanged: (value) => setState(() => _phone = value),
                                    decoration: InputDecoration(
                                      hintText: '10-digit number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
