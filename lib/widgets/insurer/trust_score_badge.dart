import 'package:flutter/material.dart';

import '../../theme/insurer_colors.dart';

class InsurerTrustScoreBadge extends StatelessWidget {
  const InsurerTrustScoreBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score > 70
        ? InsurerColors.success
        : score >= 40
            ? InsurerColors.warning
            : InsurerColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${score.toInt()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}