import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/trigger_event.dart';
import '../../models/worker.dart';
import '../../providers/payout_provider.dart';
import '../../providers/policy_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/ml_premium_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/teal_header.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with TickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _barCtrl.forward());
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worker = context.watch<WorkerProvider>().worker;
    final policy = context.watch<PolicyProvider>().policy;
    final payoutProvider = context.watch<PayoutProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (worker == null) return const Center(child: Text('Loading...'));

    // Run ML engine for breakdown display
    final rainTrigger = weatherProvider.triggers
        .where((t) => t.type == TriggerType.rain)
        .cast<TriggerEvent?>()
        .firstWhere((_) => true, orElse: () => null);

    final breakdown = MLPremiumEngine.calculate(
      worker: worker,
      payoutHistory: payoutProvider.history,
      currentRainPercent: rainTrigger?.percent ?? 0.0,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          flexibleSpace: FlexibleSpaceBar(
            background: TealHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Protection Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Active coverage · Auto-renews Monday',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            // Plan card (enhanced)
            _PlanCard(worker: worker, policy: policy, money: money),
            const SizedBox(height: 12),
            // ML Breakdown — the differentiator
            _MLBreakdownCard(breakdown: breakdown, anim: _barAnim),
            const SizedBox(height: 12),
            // Covered events chips
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COVERED EVENTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSoft,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _Chip('Rain', Icons.water_drop_outlined, AppColors.info),
                      _Chip('Heat', Icons.thermostat, AppColors.warning),
                      _Chip(
                        'Traffic',
                        Icons.directions_car_outlined,
                        AppColors.textMid,
                      ),
                      _Chip('AQI', Icons.air, AppColors.danger),
                      _Chip('Flood', Icons.flood, AppColors.info),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Trigger thresholds
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRIGGER THRESHOLDS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSoft,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Threshold(
                    icon: Icons.umbrella,
                    name: 'Rainfall',
                    value: '>20mm/2hr',
                    color: AppColors.info,
                  ),
                  const _Threshold(
                    icon: Icons.thermostat,
                    name: 'Heat Index',
                    value: '>42°C',
                    color: AppColors.warning,
                  ),
                  const _Threshold(
                    icon: Icons.air,
                    name: 'Air Quality',
                    value: '>400 AQI',
                    color: AppColors.danger,
                  ),
                  const _Threshold(
                    icon: Icons.flood,
                    name: 'Flood Alert',
                    value: 'IMD Red',
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Plan assignment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI-Managed Plan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your premium is automatically set by the GigShield AI engine every week based on 7 live signals including zone history, weather, platform, and your own delivery record.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ])),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Plan Header Card
// ──────────────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.worker,
    required this.policy,
    required this.money,
  });
  final Worker worker;
  final dynamic policy;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141E5A64),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryMid, AppColors.primaryLight],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker.tierDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      worker.fullZone,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    'Weekly Premium',
                    money.format(policy?.weeklyPremium ?? worker.weeklyPremium),
                    bigValue: true,
                  ),
                  _row(
                    'Coverage Limit',
                    '${money.format(worker.coverageLimit)}/week',
                  ),
                  _row('Status', 'Active', valueColor: AppColors.success),
                  _row('Renews', policy?.renewalDate ?? 'Every Monday'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bigValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bigValue ? 20 : 14,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ML Breakdown Card — shows all 7 signals that set the premium
// ──────────────────────────────────────────────────────────────────────────────
class _MLBreakdownCard extends StatelessWidget {
  const _MLBreakdownCard({required this.breakdown, required this.anim});
  final PremiumBreakdown breakdown;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HOW YOUR PREMIUM IS CALCULATED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGlow,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '7 signals',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Zone flood score',
            detail: breakdown.riskLabel,
            amount: _fmt(breakdown.zoneAdjustmentPercent),
            isPositive: breakdown.zoneAdjustmentPercent >= 0,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Season (${breakdown.seasonLabel})',
            detail: '×${breakdown.seasonalMultiplier.toStringAsFixed(2)}',
            amount: breakdown.seasonalMultiplier >= 1.0
                ? '+${((breakdown.seasonalMultiplier - 1) * 100).toInt()}%'
                : '−${((1 - breakdown.seasonalMultiplier) * 100).toInt()}%',
            isPositive: breakdown.seasonalMultiplier >= 1.0,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Claim history',
            detail: breakdown.claimLabel,
            amount: _fmt(breakdown.claimAdjustmentPercent),
            isPositive: breakdown.claimAdjustmentPercent <= 0,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Trust score bonus',
            detail:
                '${context.read<WorkerProvider>().worker?.trustScore.toInt() ?? 0}/100',
            amount: _fmt(breakdown.trustBonusPercent),
            isPositive: true,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Live rain proximity',
            detail: 'Real-time',
            amount: _fmt(breakdown.proximityAdjustmentPercent),
            isPositive: breakdown.proximityAdjustmentPercent <= 0,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Platform demand',
            detail: 'Rain demand spike',
            amount: _fmt(breakdown.platformAdjustmentPercent),
            isPositive: breakdown.platformAdjustmentPercent <= 0,
            anim: anim,
          ),
          _BreakdownRow(
            label: 'Zone × season compound',
            detail: 'Non-linear',
            amount: _fmt(breakdown.interactionTermPercent),
            isPositive: breakdown.interactionTermPercent <= 0,
            anim: anim,
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.darkBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Final premium',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '₹${breakdown.finalPremium.toInt()}/week',
                style: const TextStyle(
                  color: AppColors.primaryGlow,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val >= 0) return '+${val.toInt()}%';
    return '${val.toInt()}%';
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.detail,
    required this.amount,
    required this.isPositive,
    required this.anim,
  });
  final String label;
  final String detail;
  final String amount;
  final bool isPositive;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Chip and Threshold widgets
// ──────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Threshold extends StatelessWidget {
  const _Threshold({
    required this.icon,
    required this.name,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String name;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
