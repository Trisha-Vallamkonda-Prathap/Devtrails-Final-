import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../providers/payout_provider.dart';
import '../../providers/policy_provider.dart';
import '../../providers/role_provider.dart';
import '../../services/backend_url_service.dart';
import '../../providers/worker_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_utils.dart';
import '../main/main_shell.dart';
import '../subscription_payment_screen.dart';
import 'set_password_screen.dart';
import 'terms_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.role,
    this.isReturningUser = false,
    this.debugOtp,
  });

  final String phone;
  final AppRole role;
  final bool isReturningUser;
  final String? debugOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _complete = false;
  bool _verifying = false;
  int _seconds = 30;
  Timer? _timer;
  late TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
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

  Future<void> _verify(String otp) async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    setState(() => _verifying = true);

    try {
      // Verify OTP with backend
      final backendUrl = await BackendUrlService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$backendUrl/auth/verify_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        await context.read<RoleProvider>().setRole(widget.role);
        await AuthUtils.markLoggedIn();

        final userId = AuthUtils.userIdFromPhone(phone: widget.phone, role: widget.role);
        final isFirstLogin = await AuthUtils.isFirstLogin(userId);

        if (!mounted) return;

        if (isFirstLogin) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute<void>(
              builder: (_) => SetPasswordScreen(role: widget.role, phone: widget.phone),
            ),
            (route) => false,
          );
          return;
        }

        if (widget.role == AppRole.worker) {
          final workerProvider = context.read<WorkerProvider>();
          await workerProvider.init();
          final worker = workerProvider.worker;

          if (!mounted) return;

          if (worker == null) {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute<void>(
                builder: (_) => TermsScreen(phone: widget.phone),
              ),
              (route) => false,
            );
            return;
          }

          final policyProvider = context.read<PolicyProvider>();
          await policyProvider.loadPolicy(worker.id);

          if (!mounted) return;

          if (policyProvider.activePolicy == null) {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute<void>(
                builder: (_) => const SubscriptionPaymentScreen(
                  tier: 'Standard',
                  premium: 120.0,
                ),
              ),
              (route) => false,
            );
            return;
          }

          context.read<PayoutProvider>().init();
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute<void>(builder: (_) => const MainShell()),
            (route) => false,
          );
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute<void>(
            builder: (_) => TermsScreen(phone: widget.phone),
          ),
          (route) => false,
        );
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Failed to verify OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request timed out. Please check backend/network and try again.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
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
                            widget.isReturningUser ? 'Welcome back! Verify to continue.' : 'OTP sent to ${widget.phone}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                            ),
                          ),
                          if (widget.debugOtp != null && widget.debugOtp!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Fallback OTP: ${widget.debugOtp}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                                controller: _otpController,
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
                                  setState(() => _complete = true);
                                  _verify(value);
                                },
                                onChanged: (value) => setState(() => _complete = value.length == 6),
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
                                onPressed: _complete ? () => _verify(_otpController.text) : null,
                              ),
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
