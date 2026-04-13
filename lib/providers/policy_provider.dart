import 'package:flutter/foundation.dart';

import '../models/payout.dart';
import '../models/policy.dart';
import '../services/ml_premium_engine.dart';
import '../models/worker.dart';
import '../services/risk_engine.dart';

class PolicyProvider extends ChangeNotifier {
  Policy? _policy;
  PremiumBreakdown? _lastBreakdown;
  bool _loading = false;

  Policy? get policy => _policy;
  Policy? get activePolicy => _policy?.isActive == true ? _policy : null;
  PremiumBreakdown? get lastBreakdown => _lastBreakdown;
  bool get loading => _loading;

  Future<bool> purchase(
    Worker worker, {
    List<Payout> payoutHistory = const <Payout>[],
    double currentRainPercent = 0.5,
  }) async {
    _loading = true;
    notifyListeners();

    final now = DateTime.now();
    final tier = RiskEngine.getTier(worker.zone);
    final breakdown = MLPremiumEngine.calculate(
      worker: worker,
      payoutHistory: payoutHistory,
      currentRainPercent: currentRainPercent,
      asOf: now,
    );
    _lastBreakdown = breakdown;

    _policy = Policy(
      id: 'POL-${now.millisecondsSinceEpoch}',
      workerId: worker.id,
      status: PolicyStatus.active,
      tier: tier,
      weeklyPremium: breakdown.finalPremium,
      coverageLimit: worker.coverageLimit,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      coveredEvents: const ['Rain', 'Heat', 'AQI', 'Cyclone', 'Flash Flood'],
    );

    _loading = false;
    notifyListeners();
    return true;
  }
}
