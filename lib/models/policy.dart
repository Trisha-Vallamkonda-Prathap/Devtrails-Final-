import 'package:intl/intl.dart';

import 'worker.dart';

enum PolicyStatus { active, expired, cancelled }

class Policy {
  const Policy({
    required this.id,
    required this.workerId,
    required this.status,
    required this.tier,
    required this.weeklyPremium,
    required this.coverageLimit,
    required this.startDate,
    required this.endDate,
    required this.coveredEvents,
  });

  final String id;
  final String workerId;
  final PolicyStatus status;
  final RiskTier tier;
  final double weeklyPremium;
  final double coverageLimit;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> coveredEvents;

  bool get isActive =>
      status == PolicyStatus.active && endDate.isAfter(DateTime.now());

  String get renewalDate => DateFormat('EEE, d MMM').format(endDate);

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      status: PolicyStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PolicyStatus.active,
      ),
      tier: RiskTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => RiskTier.medium,
      ),
      weeklyPremium: (json['weeklyPremium'] as num).toDouble(),
      coverageLimit: (json['coverageLimit'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      coveredEvents: List<String>.from(json['coveredEvents'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'status': status.name,
      'tier': tier.name,
      'weeklyPremium': weeklyPremium,
      'coverageLimit': coverageLimit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'coveredEvents': coveredEvents,
    };
  }
}
