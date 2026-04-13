import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'profile_setup_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_scrolledToBottom) {
          setState(() => _scrolledToBottom = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _accept() {
    Navigator.push(
      context,
      CupertinoPageRoute<void>(builder: (_) => const ProfileSetupScreen()),
    );
  }

  Widget _termsSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GigShield Terms of Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Last updated: March 2026',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _termsSection(
                    '1. Income Protection Coverage',
                    'GigShield provides parametric income protection for delivery partners. Coverage is activated upon payment of the weekly premium and remains valid for 7 calendar days from activation.',
                  ),
                  _termsSection(
                    '2. Parametric Triggers',
                    'Payouts are triggered automatically when environmental conditions in your registered delivery zone exceed predefined thresholds including rainfall, heat index, AQI, flood alerts, and verified closures.',
                  ),
                  _termsSection(
                    '3. Payout Policy',
                    'Payouts are calculated as a percentage of your declared weekly average earnings proportional to disrupted hours. Maximum weekly payout is capped at your coverage limit.',
                  ),
                  _termsSection(
                    '4. Fraud Prevention',
                    'GigShield uses GPS verification, platform activity checks, and behavioral anomaly monitoring. Fraudulent activity may result in suspension and legal review.',
                  ),
                  _termsSection(
                    '5. Privacy & Data',
                    'We collect location and sensor signals solely for trigger verification and fraud prevention. Data is encrypted and never sold to third parties.',
                  ),
                  _termsSection(
                    '6. Cancellation',
                    'Workers may cancel weekly policy before Monday 00:00 for full refund if no payout has been initiated.',
                  ),
                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'Scroll to the bottom to accept',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _scrolledToBottom ? 100 : 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: GradientButton(
                label: 'I Accept & Continue →',
                onPressed: _scrolledToBottom ? _accept : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
