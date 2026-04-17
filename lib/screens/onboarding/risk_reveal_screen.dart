import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/trigger_event.dart';
import '../../models/worker.dart';
import '../../providers/payout_provider.dart';
import '../../providers/policy_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/risk_engine.dart';
import '../subscription_payment_screen.dart';

class RiskRevealScreen extends StatefulWidget {
  const RiskRevealScreen({super.key, required this.worker});

  final Worker worker;

  @override
  State<RiskRevealScreen> createState() => _RiskRevealScreenState();
}

class _RiskRevealScreenState extends State<RiskRevealScreen> {
  bool _showReveal = false;
  bool _showBadge = false;
  bool _activating = false;

  Color get _bgColor {
    switch (widget.worker.tier) {
      case RiskTier.high:
        return const Color(0xFF1F0808);
      case RiskTier.low:
        return const Color(0xFF081F10);
      case RiskTier.medium:
        return AppColors.darkBg;
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showReveal = true);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() => _showBadge = true);
      }
    });
  }

  Future<void> _activate() async {
    setState(() => _activating = true);
    final weatherProvider = context.read<WeatherProvider>();
    final payoutProvider = context.read<PayoutProvider>();
    final rainTrigger = weatherProvider.triggers
        .where((t) => t.type == TriggerType.rain)
        .cast<TriggerEvent?>()
        .firstWhere(
          (t) => t != null,
          orElse: () => null,
        );
    final policyProvider = context.read<PolicyProvider>();
    await policyProvider.purchase(
      widget.worker,
      payoutHistory: payoutProvider.history,
      currentRainPercent: rainTrigger?.percent ?? 0.5,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_has_paid_subscription');
    payoutProvider.init();
    await weatherProvider.fetch(widget.worker.fullZone);
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute<void>(
        builder: (_) => SubscriptionPaymentScreen(
          tier: policyProvider.policy?.tier.name ?? widget.worker.tier.name,
          premium: policyProvider.policy?.weeklyPremium ??
              RiskEngine.getPremium(widget.worker.tier,
                  city: widget.worker.city),
          hasValidSubscription: false,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.worker.tier == RiskTier.high
        ? 0.78
        : widget.worker.tier == RiskTier.medium
            ? 0.55
            : 0.32;
    final tierColor = AppColors.tierColor(widget.worker.tier.name);
    final premium =
        RiskEngine.getPremium(widget.worker.tier, city: widget.worker.city);
    final limit = RiskEngine.getCoverageLimit(widget.worker.tier,
        city: widget.worker.city);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: !_showReveal
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Analyzing your zone...',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 40),
                        ...List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Shimmer.fromColors(
                              baseColor: const Color(0xFF1A3A44),
                              highlightColor: const Color(0xFF1A5A64),
                              child: Container(
                                width: 280,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Weather patterns',
                                  style: TextStyle(
                                      color: AppColors.textSoft, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Zone history',
                                  style: TextStyle(
                                      color: AppColors.textSoft, fontSize: 11)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Risk factors',
                                  style: TextStyle(
                                      color: AppColors.textSoft, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text(
                        'Your Risk Profile',
                        style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 13,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 40),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          return SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 14,
                                  backgroundColor: Colors.white12,
                                  strokeCap: StrokeCap.round,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(tierColor),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(value * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'risk',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      AnimatedOpacity(
                        opacity: _showBadge ? 1 : 0,
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: tierColor.withValues(alpha: 0.6),
                                width: 1.5),
                          ),
                          child: Text(
                            '${widget.worker.tier.name.toUpperCase()} RISK ZONE',
                            style: TextStyle(
                                color: tierColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          RiskEngine.getReason(
                              widget.worker.tier, widget.worker.zone),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Weekly premium',
                                      style: TextStyle(
                                          color: AppColors.textSoft,
                                          fontSize: 12)),
                                  Text('₹${premium.toInt()}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 44,
                                color: AppColors.darkBorder),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Coverage limit',
                                      style: TextStyle(
                                          color: AppColors.textSoft,
                                          fontSize: 12)),
                                  Text('₹${limit.toInt()}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Activate Coverage →',
                        isLoading: _activating,
                        onPressed: _activate,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
