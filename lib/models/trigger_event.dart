import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TriggerType { rain, heat, flood, closure, aqi, cyclone, flashFlood }

class TriggerEvent {
  const TriggerEvent({
    required this.id,
    required this.zone,
    required this.unit,
    required this.type,
    required this.currentValue,
    required this.threshold,
    required this.isTriggered,
    required this.detectedAt,
  });

  final String id;
  final String zone;
  final String unit;
  final TriggerType type;
  final double currentValue;
  final double threshold;
  final bool isTriggered;
  final DateTime detectedAt;

  double get percent => (currentValue / threshold).clamp(0.0, 1.0);

  String get statusLabel {
    if (type == TriggerType.cyclone || type == TriggerType.flashFlood) {
      return currentValue >= 1.0 ? 'ALERT ACTIVE' : 'Monitoring';
    }
    if (isTriggered) {
      return 'TRIGGERED';
    }
    if (percent > 0.7) {
      return 'Near';
    }
    return 'Clear';
  }

  Color get statusColor {
    if (type == TriggerType.cyclone || type == TriggerType.flashFlood) {
      return currentValue >= 1.0 ? AppColors.danger : AppColors.success;
    }
    if (isTriggered) {
      return AppColors.danger;
    }
    if (percent > 0.7) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String get displayName {
    switch (type) {
      case TriggerType.rain:
        return 'Rainfall';
      case TriggerType.heat:
        return 'Heat Index';
      case TriggerType.flood:
        return 'Flood Alert';
      case TriggerType.closure:
        return 'Zone Closure';
      case TriggerType.aqi:
        return 'Air Quality';
      case TriggerType.cyclone:
        return 'Cyclone Alert';
      case TriggerType.flashFlood:
        return 'Flash Flood';
    }
  }

  String get emoji {
    switch (type) {
      case TriggerType.rain:
        return '🌧️';
      case TriggerType.heat:
        return '🌡️';
      case TriggerType.flood:
        return '🌊';
      case TriggerType.closure:
        return '🚫';
      case TriggerType.aqi:
        return '💨';
      case TriggerType.cyclone:
        return '🌀';
      case TriggerType.flashFlood:
        return '🌊';
    }
  }

  factory TriggerEvent.fromJson(Map<String, dynamic> json) {
    return TriggerEvent(
      id: json['id'] as String,
      zone: json['zone'] as String,
      unit: json['unit'] as String,
      type: TriggerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TriggerType.rain,
      ),
      currentValue: (json['currentValue'] as num).toDouble(),
      threshold: (json['threshold'] as num).toDouble(),
      isTriggered: json['isTriggered'] as bool,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone': zone,
      'unit': unit,
      'type': type.name,
      'currentValue': currentValue,
      'threshold': threshold,
      'isTriggered': isTriggered,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }
}
