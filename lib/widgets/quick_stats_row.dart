import 'package:flutter/material.dart';
import 'package:gigshield/providers/payout_provider.dart';
import 'package:gigshield/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final payoutProvider = Provider.of<PayoutProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: "💰",
            label: "This Week",
            value: currencyFormat.format(payoutProvider.thisWeek),
            subLabel: "protected",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            emoji: "📊",
            label: "Total Saved",
            value: currencyFormat.format(payoutProvider.totalProtected),
            subLabel: "all time",
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String subLabel;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1E5A64),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            subLabel,
            style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}
