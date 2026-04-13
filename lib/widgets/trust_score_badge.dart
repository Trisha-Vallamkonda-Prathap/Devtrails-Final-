import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TrustScoreBadge extends StatelessWidget {
  const TrustScoreBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final icon = score >= 90
        ? Icons.verified
        : score >= 70
            ? Icons.shield
            : Icons.warning;
    final color = score >= 90
        ? AppColors.success
        : score >= 70
            ? AppColors.warning
            : AppColors.danger;
    final label = score >= 90
        ? 'Verified'
        : score >= 70
            ? 'Good'
            : 'Review';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
