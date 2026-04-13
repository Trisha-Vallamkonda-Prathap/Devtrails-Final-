import 'package:flutter/material.dart';

import '../models/trigger_event.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class TriggerMonitorCard extends StatelessWidget {
  const TriggerMonitorCard({super.key, required this.triggers});

  final List<TriggerEvent> triggers;

  @override
  Widget build(BuildContext context) {
    final anyTriggered = triggers.any((t) => t.isTriggered);
    final anyNear = triggers.any((t) => !t.isTriggered && t.percent > 0.7);
    final dotColor = anyTriggered
        ? AppColors.danger
        : anyNear
            ? AppColors.warning
            : AppColors.success;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'LIVE TRIGGER MONITOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSoft,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (triggers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No triggers available right now.'),
            )
          else
            ...triggers.asMap().entries.map((entry) {
              final i = entry.key;
              final trigger = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: trigger.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(trigger.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trigger.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Threshold: ${trigger.threshold}${trigger.unit}  ·  Now: ${trigger.currentValue}${trigger.unit}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(trigger: trigger),
                    ],
                  ),
                  if (i != triggers.length - 1) const Divider(color: AppColors.divider),
                ],
              );
            }),
          if (anyTriggered) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.danger, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Disruption active — payout processing',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.trigger});

  final TriggerEvent trigger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trigger.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        trigger.statusLabel,
        style: TextStyle(color: trigger.statusColor, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
