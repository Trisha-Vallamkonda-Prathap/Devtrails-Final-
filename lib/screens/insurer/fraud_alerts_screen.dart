import 'package:flutter/material.dart';

import '../../data/insurer/mock_data.dart';
import '../../theme/insurer_colors.dart';
import 'worker_profile_sheet.dart';

class FraudAlertsScreen extends StatelessWidget {
  const FraudAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [...mockFraudAlerts]
      ..sort((a, b) => b.compositeScore(DateTime.now()).compareTo(a.compositeScore(DateTime.now())));

    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        title: const Text(
          'Fraud Alerts',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final borderColor = alert.riskScore > 80
              ? InsurerColors.accent
              : alert.riskScore >= 50
                  ? InsurerColors.warning
                  : InsurerColors.border;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InsurerColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border(left: BorderSide(color: borderColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.worker.name,
                            style: const TextStyle(
                              color: InsurerColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.worker.id,
                            style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${alert.riskScore.toInt()}',
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _timeSince(alert.flaggedAt),
                  style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.worker.primarySignal,
                  style: const TextStyle(
                    color: InsurerColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor == InsurerColors.border ? InsurerColors.elevated : borderColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => WorkerProfileSheet(worker: alert.worker),
                      );
                    },
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: alerts.length,
      ),
    );
  }

  String _timeSince(DateTime flaggedAt) {
    final diff = DateTime.now().difference(flaggedAt);
    if (diff.inDays > 0) {
      return 'Flagged ${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return 'Flagged ${diff.inHours}h ago';
    }
    return 'Flagged ${diff.inMinutes}m ago';
  }
}
