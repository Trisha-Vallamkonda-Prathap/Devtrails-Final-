import 'package:flutter/material.dart';

import '../../models/insurer_models.dart';
import '../../theme/insurer_colors.dart';
import 'trust_score_badge.dart';

class WorkerListTile extends StatelessWidget {
  const WorkerListTile({
    super.key,
    required this.worker,
    required this.onTap,
  });

  final InsurerWorker worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreColor = worker.trustScore > 70
        ? InsurerColors.success
        : worker.trustScore >= 40
            ? InsurerColors.warning
            : InsurerColors.accent;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: InsurerColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: InsurerColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: InsurerColors.elevated,
              child: Text(
                worker.initials,
                style: const TextStyle(
                  color: InsurerColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker.name,
                          style: const TextStyle(
                            color: InsurerColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        worker.isFlagged ? Icons.flag : Icons.outlined_flag,
                        color: worker.isFlagged ? InsurerColors.accent : InsurerColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${worker.id} · ${worker.city}',
                    style: const TextStyle(
                      color: InsurerColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InsurerTrustScoreBadge(score: worker.trustScore),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          worker.primarySignal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: InsurerColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 52,
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}