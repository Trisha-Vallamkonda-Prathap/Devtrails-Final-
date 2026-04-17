import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/worker_provider.dart';
import '../screens/onboarding/zone_map_screen.dart';
import '../services/risk_engine.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

/// BUG FIX 4: AI recommendation ONLY suggests — never auto-switches.
/// Tapping "Switch" triggers the SAME validation flow as manual selection
/// (confirmation dialog → fresh GPS → geofence check).
class ZoneRecommenderCard extends StatelessWidget {
  const ZoneRecommenderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final worker = context.watch<WorkerProvider>().worker;
    if (worker == null) return const SizedBox.shrink();

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
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your zone is stable ✓',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${worker.fullZone} has low disruption risk. No switch needed.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _RecommendCard(rec: rec);
  }
}

class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.rec});
  final Map<String, String> rec;

  /// BUG FIX 4: navigate to ZoneMapScreen pre-filtered to the recommended
  /// zone — user must go through the full confirmation + GPS + geofence flow.
  /// NO bypass. NO auto-switch.
  Future<void> _navigateToZoneSwitch(BuildContext context) async {
    final worker = context.read<WorkerProvider>().worker;
    if (worker == null) return;

    // Resolve city for the recommended zone
    final recommendedZoneName = rec['zone'] ?? '';

    // Find what city this zone belongs to — check kZoneCity from location_service
    // We pass the worker's current city as default; ZoneMapScreen will show it
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute<Map<String, dynamic>>(
        builder: (_) => ZoneMapScreen(
          cityName: worker.city,
          isOnboarding: false,
        ),
      ),
    );

    // result is non-null only if the user completed the full validation flow
    // and the zone was actually switched inside _finalizeZoneSwitch
    if (result != null && context.mounted) {
      final switchedTo = result['zone'] as String? ?? recommendedZoneName;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Switched to $switchedTo'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = context.watch<WorkerProvider>().worker;
    if (worker == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x141E5A64),
              blurRadius: 12,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F9),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
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
          // ── Body ──
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
                              worker.fullZone,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8AADB2)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward,
                              size: 14, color: Color(0xFF0E6B74)),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8AADB2)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // BUG FIX 4: clear label that this is a suggestion only
                      const Text(
                        'Tap Switch to verify & move to this zone.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0E6B74),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  // BUG FIX 4: triggers validation flow, NOT direct switch
                  onPressed: () => _navigateToZoneSwitch(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E6B74),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
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
}