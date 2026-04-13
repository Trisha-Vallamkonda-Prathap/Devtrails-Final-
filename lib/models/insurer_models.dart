class FraudSignalSummary {
  const FraudSignalSummary({
    required this.deviceSensorFusion,
    required this.platformActivityCoherence,
    required this.geospatialPlausibility,
    required this.fraudRingDetection,
    required this.mobilityContext,
    required this.trustScore,
  });

  final bool deviceSensorFusion;
  final bool platformActivityCoherence;
  final bool geospatialPlausibility;
  final bool fraudRingDetection;
  final bool mobilityContext;
  final bool trustScore;

  bool get hasTriggers =>
      deviceSensorFusion ||
      platformActivityCoherence ||
      geospatialPlausibility ||
      fraudRingDetection ||
      mobilityContext ||
      trustScore;

  List<MapEntry<String, bool>> get layers => [
        MapEntry('Device Sensor Fusion', deviceSensorFusion),
        MapEntry('Platform Activity Coherence', platformActivityCoherence),
        MapEntry('Geospatial Plausibility', geospatialPlausibility),
        MapEntry('Fraud Ring Detection', fraudRingDetection),
        MapEntry('Mobility Context', mobilityContext),
        MapEntry('Trust Score', trustScore),
      ];
}

class ClaimRecord {
  const ClaimRecord({
    required this.date,
    required this.triggerType,
    required this.amount,
    required this.status,
  });

  final DateTime date;
  final String triggerType;
  final int amount;
  final String status;
}

class InsurerWorker {
  const InsurerWorker({
    required this.id,
    required this.name,
    required this.city,
    required this.joinDate,
    required this.trustScore,
    required this.isFlagged,
    required this.activeClaims,
    required this.primarySignal,
    required this.claimHistory,
    required this.signals,
  });

  final String id;
  final String name;
  final String city;
  final DateTime joinDate;
  final double trustScore;
  final bool isFlagged;
  final int activeClaims;
  final String primarySignal;
  final List<ClaimRecord> claimHistory;
  final FraudSignalSummary signals;

  String get initials {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class FraudAlertItem {
  const FraudAlertItem({
    required this.worker,
    required this.riskScore,
    required this.flaggedAt,
  });

  final InsurerWorker worker;
  final double riskScore;
  final DateTime flaggedAt;

  double compositeScore(DateTime now) {
    final recencyHours = now.difference(flaggedAt).inHours.clamp(1, 24 * 30);
    final recencyScore = (1 - (recencyHours / (24 * 30))).clamp(0.0, 1.0);
    return (riskScore * 0.6) + ((recencyScore * 100) * 0.4);
  }
}

class CityRiskEntry {
  const CityRiskEntry({
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.claimDensity,
    required this.activeWorkers,
    required this.claimsThisMonth,
    required this.fraudFlags,
  });

  final String city;
  final double latitude;
  final double longitude;
  final int claimDensity;
  final int activeWorkers;
  final int claimsThisMonth;
  final int fraudFlags;
}

class PayoutByCityEntry {
  const PayoutByCityEntry({
    required this.city,
    required this.amount,
  });

  final String city;
  final int amount;
}

class TriggerBreakdownEntry {
  const TriggerBreakdownEntry({
    required this.label,
    required this.amount,
  });

  final String label;
  final int amount;
}

class MonthlyPayoutEntry {
  const MonthlyPayoutEntry({
    required this.month,
    required this.amount,
  });

  final String month;
  final int amount;
}