import 'package:flutter/material.dart';

import '../models/payout.dart';
import '../theme/app_colors.dart';

class PayoutHistoryTile extends StatelessWidget {
  const PayoutHistoryTile({super.key, required this.payout});

  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final accepted = payout.status == PayoutStatus.accepted;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: payout.statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(payout.triggerEmoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payout.triggerDisplayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                payout.formattedDate,
                style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              payout.formattedAmount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accepted ? AppColors.primary : AppColors.textSoft,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: payout.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payout.status.name,
                style: TextStyle(color: payout.statusColor, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
