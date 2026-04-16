import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../services/otp_service.dart';
import '../../providers/payout_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/worker_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_utils.dart';
import '../insurer/insurance_dashboard_screen.dart';
import '../main/main_shell.dart';
import 'set_password_screen.dart';
import 'terms_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.role,
    this.isReturningUser = false,
  });

  final String phone;
  final AppRole role;
  final bool isReturningUser;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _complete = false;
  bool _verifying = false;
  String _otp = '';
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

Future<void> _verify() async {
  setState(() => _verifying = true);

  final success = await OtpService.verifyOtp(_otp);

  if (!mounted) return;

  setState(() => _verifying = false);

  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid OTP')),
    );
    return;
  }

  await context.read<RoleProvider>().setRole(widget.role);
  await AuthUtils.markLoggedIn();

  final userId = AuthUtils.userIdFromPhone(
    phone: widget.phone,
    role: widget.role,
  );

  final isFirstLogin = await AuthUtils.isFirstLogin(userId);

  if (!mounted) return;

  // KEEP YOUR EXISTING NAVIGATION LOGIC BELOW
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            'Verify your number',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.isReturningUser ? 'Welcome back! Verify to continue.' : 'OTP sent to +91 ${widget.phone}',
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔐 ENTER OTP',
                                style: TextStyle(
                                  color: AppColors.textSoft,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              PinCodeTextField(
                                appContext: context,
                                length: 6,
                                keyboardType: TextInputType.number,
                                animationType: AnimationType.scale,
                                enableActiveFill: true,
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(12),
                                  fieldHeight: 52,
                                  fieldWidth: 44,
                                  activeFillColor: AppColors.tealLight,
                                  inactiveFillColor: const Color(0xFFF5F5F5),
                                  selectedFillColor: AppColors.tealLight,
                                  activeColor: AppColors.primary,
                                  inactiveColor: AppColors.divider,
                                  selectedColor: AppColors.primary,
                                ),
                                onCompleted: (value) {
                                  setState(() {
                                    _otp = value;
                                    _complete = true;
                                  });
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _otp = value;
                                    _complete = value.length == 6;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: _seconds > 0
                                    ? Text(
                                        'Resend in 0:${_seconds.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: AppColors.textSoft,
                                          fontSize: 12,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _startTimer,
                                        child: const Text('Resend OTP'),
                                      ),
                              ),
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Verify OTP',
                                isLoading: _verifying,
                                onPressed: _complete ? _verify : null,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
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
