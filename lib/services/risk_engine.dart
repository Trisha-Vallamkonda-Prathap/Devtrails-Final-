import '../config.dart';
import '../models/worker.dart';

class RiskEngine {
  static RiskTier getTier(String zone, {String? city}) {
    // City-level tier takes priority
    if (city != null) {
      final cityTier = kCityTiers[city];
      if (cityTier != null) {
        switch (cityTier) {
          case 'high':
            return RiskTier.high;
          case 'low':
            return RiskTier.low;
          default:
            return RiskTier.medium;
        }
      }
    }

    // Fallback: infer city from zone name
    if (zone.contains('Mumbai') ||
        zone.contains('Kurla') ||
        zone.contains('Dharavi') ||
        zone.contains('Andheri') ||
        zone.contains('Dadar') ||
        zone.contains('Bandra')) {
      return RiskTier.high;
    }
    if (zone.contains('Delhi') ||
        zone.contains('Connaught') ||
        zone.contains('Lajpat') ||
        zone.contains('Rohini') ||
        zone.contains('Dwarka')) {
      return RiskTier.high;
    }
    if (zone.contains('Chennai') ||
        zone.contains('Tambaram') ||
        zone.contains('Guindy') ||
        zone.contains('Velachery') ||
        zone.contains('Anna Nagar')) {
      return RiskTier.low;
    }
    if (zone.contains('Pune') ||
        zone.contains('Kothrud') ||
        zone.contains('Hinjawadi') ||
        zone.contains('Hadapsar')) {
      return RiskTier.low;
    }
    return RiskTier.medium; // Bengaluru, Hyderabad, others
  }

  static double getPremium(RiskTier t, {String? city}) {
    if (city != null && kCityPremiums.containsKey(city)) {
      return kCityPremiums[city]!;
    }
    switch (t) {
      case RiskTier.high:
        return 120.0;
      case RiskTier.medium:
        return 90.0;
      case RiskTier.low:
        return 60.0;
    }
  }

  static double getCoverageLimit(RiskTier t, {String? city}) {
    if (city != null && kCityCoverage.containsKey(city)) {
      return kCityCoverage[city]!;
    }
    switch (t) {
      case RiskTier.high:
        return 2500.0;
      case RiskTier.medium:
        return 2240.0;
      case RiskTier.low:
        return 2000.0;
    }
  }

  static double getRiskScore(RiskTier tier) {
    switch (tier) {
      case RiskTier.high:
        return 0.78;
      case RiskTier.medium:
        return 0.55;
      case RiskTier.low:
        return 0.32;
    }
  }

  static String getReason(RiskTier tier, String zone) {
    switch (tier) {
      case RiskTier.high:
        return 'This zone has significant flood and waterlogging history.';
      case RiskTier.medium:
        return 'This zone has moderate seasonal disruption history.';
      case RiskTier.low:
        return 'This zone has stable conditions and low historical disruptions.';
    }
  }

  static Map<String, String>? getRecommendation(String zone) {
    final hit = kZones.where((z) => z['zone'] == zone).cast<Map<String, dynamic>>();
    if (hit.isEmpty) {
      return null;
    }
    final zoneData = hit.first;
    if (zoneData['rec'] == null) {
      return null;
    }
    return {
      'zone': zoneData['rec'] as String,
      'boost': zoneData['boost'] as String,
      'boostReason': zoneData['boostReason'] as String,
    };
  }

  static bool _containsAny(String zone, List<String> probes) {
    return probes.any((p) => zone.toLowerCase().contains(p.toLowerCase()));
  }
}
