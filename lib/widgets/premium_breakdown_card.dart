import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/ml_premium_engine.dart';
import '../theme/app_colors.dart';

class PremiumBreakdownCard extends StatelessWidget {
  const PremiumBreakdownCard({super.key, required this.breakdown});

  final PremiumBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x141E5A64), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: breakdown.isCheaper ? AppColors.success.withValues(alpha: 0.08) : AppColors.warning.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  breakdown.isCheaper ? Icons.trending_down : Icons.trending_up,
                  color: breakdown.isCheaper ? AppColors.success : AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    breakdown.isCheaper ? 'AI reduced your premium this week' : 'AI adjusted your premium this week',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: breakdown.isCheaper ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: breakdown.isCheaper ? AppColors.success : AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fmt.format(breakdown.finalPremium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Base premium',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft),
                  ),
                ),
                Text(
                  fmt.format(breakdown.basePremium),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _factorRow(
            icon: Icons.location_on_outlined,
            label: '${breakdown.zone} flood history',
            sublabel: 'Zone risk score: ${(breakdown.zoneScore * 100).toInt()}%',
            adjustment: breakdown.zoneAdjustmentPercent,
          ),
          _factorRow(
            icon: Icons.calendar_month_outlined,
            label: breakdown.seasonLabel,
            sublabel: '${(breakdown.seasonalMultiplier * 100).toInt()}% seasonal multiplier',
            adjustment: ((breakdown.seasonalMultiplier - 1.0) * 100).roundToDouble(),
          ),
          _factorRow(
            icon: Icons.history_outlined,
            label: breakdown.claimLabel,
            sublabel: '${(breakdown.claimRatio * 100).toInt()}% of offers accepted',
            adjustment: breakdown.claimAdjustmentPercent,
          ),
          if (breakdown.proximityAdjustmentPercent > 0)
            _factorRow(
              icon: Icons.cloud_outlined,
              label: 'Rain nearing threshold',
              sublabel: 'Live risk adjustment',
              adjustment: breakdown.proximityAdjustmentPercent,
            ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: breakdown.isCheaper ? AppColors.success.withValues(alpha: 0.08) : AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    breakdown.isCheaper ? 'You save this week' : 'Additional cost',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: breakdown.isCheaper ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${breakdown.isCheaper ? '-' : '+'}${fmt.format(breakdown.savingsOrCost.abs())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: breakdown.isCheaper ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factorRow({
    required IconData icon,
    required String label,
    required String sublabel,
    required double adjustment,
  }) {
    final isPositive = adjustment > 0;
    final isNeutral = adjustment.abs() < 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textMid),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSoft),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isNeutral
                  ? AppColors.background
                  : isPositive
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isNeutral ? '—' : '${isPositive ? '+' : ''}${adjustment.toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isNeutral ? AppColors.textSoft : isPositive ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
