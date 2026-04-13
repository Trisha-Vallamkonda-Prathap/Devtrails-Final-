import 'package:flutter/material.dart';

import '../../models/insurer_models.dart';
import '../../theme/insurer_colors.dart';

class WorkerProfileSheet extends StatelessWidget {
  const WorkerProfileSheet({super.key, required this.worker});

  final InsurerWorker worker;

  @override
  Widget build(BuildContext context) {
    final color = worker.trustScore > 70
        ? InsurerColors.success
        : worker.trustScore >= 40
            ? InsurerColors.warning
            : InsurerColors.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.7,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: InsurerColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: InsurerColors.border)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: InsurerColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: worker.isFlagged ? InsurerColors.accent.withValues(alpha: 0.14) : InsurerColors.good.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: worker.isFlagged ? InsurerColors.accent : InsurerColors.success),
                      ),
                      child: Text(
                        worker.isFlagged ? 'FLAGGED — FRAUD RISK' : 'Verified Worker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: worker.isFlagged ? InsurerColors.accent : InsurerColors.success,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: InsurerColors.elevated,
                          child: Text(
                            worker.initials,
                            style: const TextStyle(
                              color: InsurerColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker.name,
                                style: const TextStyle(
                                  color: InsurerColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${worker.id} · ${worker.city} · Joined ${_formatDate(worker.joinDate)}',
                                style: const TextStyle(
                                  color: InsurerColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: InsurerColors.elevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: InsurerColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trust Score',
                            style: TextStyle(color: InsurerColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: CircularProgressIndicator(
                                      value: worker.trustScore / 100,
                                      strokeWidth: 12,
                                      backgroundColor: InsurerColors.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        worker.trustScore.toInt().toString(),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Text(
                                        'Trust',
                                        style: TextStyle(color: InsurerColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Claim History',
                      style: TextStyle(
                        color: InsurerColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...worker.claimHistory.map(
                      (claim) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: InsurerColors.elevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: InsurerColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _statusColor(claim.status).withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _statusIcon(claim.status),
                                  color: _statusColor(claim.status),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${claim.triggerType} · ${_formatDate(claim.date)}',
                                      style: const TextStyle(
                                        color: InsurerColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₹${claim.amount} · ${claim.status}',
                                      style: const TextStyle(
                                        color: InsurerColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fraud Signal Summary',
                      style: TextStyle(
                        color: InsurerColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: worker.signals.layers.map((layer) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: layer.value ? InsurerColors.accent.withValues(alpha: 0.16) : InsurerColors.elevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: layer.value ? InsurerColors.accent : InsurerColors.border,
                            ),
                          ),
                          child: Text(
                            layer.key,
                            style: TextStyle(
                              color: layer.value ? InsurerColors.textPrimary : InsurerColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (worker.isFlagged)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: InsurerColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Flagged',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: InsurerColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Flag Account',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return InsurerColors.success;
      case 'flagged':
        return InsurerColors.warning;
      default:
        return InsurerColors.accent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'flagged':
        return Icons.flag;
      default:
        return Icons.block;
    }
  }
}
