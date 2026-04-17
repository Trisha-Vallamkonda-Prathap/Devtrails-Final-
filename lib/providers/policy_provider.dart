import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

    await _savePolicy(worker.id);

    _loading = false;
    notifyListeners();
    return true;
  }

  Future<void> activatePolicy(String userId) async {
    final now = DateTime.now();
    if (_policy == null) {
      _policy = Policy(
        id: 'POL-${now.millisecondsSinceEpoch}',
        workerId: userId,
        status: PolicyStatus.active,
        tier: RiskTier.medium,
        weeklyPremium: 120.0,
        coverageLimit: 10000.0,
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        coveredEvents: const ['Rain', 'Heat', 'AQI', 'Cyclone', 'Flash Flood'],
      );
    } else {
      _policy = Policy(
        id: _policy!.id,
        workerId: _policy!.workerId,
        status: PolicyStatus.active,
        tier: _policy!.tier,
        weeklyPremium: _policy!.weeklyPremium,
        coverageLimit: _policy!.coverageLimit,
        startDate: _policy!.startDate,
        endDate: now.add(const Duration(days: 7)),
        coveredEvents: _policy!.coveredEvents,
      );
    }
    await _savePolicy(userId);
    notifyListeners();
  }

  Future<void> loadPolicy(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final policyJson = prefs.getString('policy_$userId');
    if (policyJson != null) {
      final data = jsonDecode(policyJson);
      _policy = Policy.fromJson(data);
    } else {
      _policy = null;
    }
    notifyListeners();
  }

  Future<void> _savePolicy(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_policy != null) {
      final data = _policy!.toJson();
      await prefs.setString('policy_$userId', jsonEncode(data));
    } else {
      await prefs.remove('policy_$userId');
    }
  }
}
