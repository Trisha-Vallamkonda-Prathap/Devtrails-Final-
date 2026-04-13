import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/worker_provider.dart';
import '../services/risk_engine.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class ZoneRecommenderCard extends StatefulWidget {
  const ZoneRecommenderCard({super.key});

  @override
  State<ZoneRecommenderCard> createState() => _ZoneRecommenderCardState();
}

class _ZoneRecommenderCardState extends State<ZoneRecommenderCard> {
  bool _switched = false;
  String? _prevZone;

  @override
  Widget build(BuildContext context) {
    final workerProvider = context.watch<WorkerProvider>();
    final worker = workerProvider.worker;
    if (worker == null) {
      return const SizedBox.shrink();
    }

    final rec = RiskEngine.getRecommendation(worker.zone);
    if (rec == null) {
      return AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your zone is stable ✓',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${worker.fullZone} has low disruption risk. No switch needed.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_switched) {
      return AppCard(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Now delivering in ${worker.zone}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text('${rec['boost']} earnings boost active', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                  ],
                ),
              ),
              TextButton(onPressed: () => _undo(workerProvider, worker), child: const Text('Undo')),
            ],
          ),
        ),
      );
    }

    return _recommendCard(worker.fullZone, rec, workerProvider, worker);
  }

  Widget _recommendCard(
    String fullZone,
    Map<String, String> rec,
    WorkerProvider workerProvider,
    dynamic worker,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x141E5A64), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFF0E6B74), size: 15),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'AI Zone Recommendation',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E6B74),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              fullZone,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF8AADB2)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: Color(0xFF0E6B74)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              rec['zone'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0E6B74),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rec['boost'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['boostReason'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8AADB2)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: () => _doSwitch(workerProvider, worker, rec),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E6B74),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Switch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSwitch(
    WorkerProvider workerProvider,
    dynamic worker,
    Map<String, String> rec,
  ) async {
    _prevZone = worker.zone;
    await workerProvider.setWorker(worker.copyWith(zone: rec['zone']));
    if (!mounted) {
      return;
    }
    setState(() => _switched = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Switched to ${rec['zone']}'),
      ),
    );
  }

  Future<void> _undo(WorkerProvider workerProvider, dynamic worker) async {
    if (_prevZone == null) {
      return;
    }
    await workerProvider.setWorker(worker.copyWith(zone: _prevZone));
    if (!mounted) {
      return;
    }
    setState(() {
      _switched = false;
      _prevZone = null;
    });
  }
}
