import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum RiskTier { low, medium, high }
enum DeliveryPlatform { zomato, zepto, dunzo, swiggy, amazon, blinkit }

class Worker {
  const Worker({
    required this.id,
    required this.name,
    required this.phone,
    required this.platform,
    required this.zone,
    required this.city,
    required this.tier,
    required this.weeklyAvgEarnings,
    required this.trustScore,
    required this.joinedAt,
    this.profileImagePath,
  });

  final String id;
  final String name;
  final String phone;
  final DeliveryPlatform platform;
  final String zone;
  final String city;
  final RiskTier tier;
  final double weeklyAvgEarnings;
  final double trustScore;
  final DateTime joinedAt;
  final String? profileImagePath;

  String get fullZone => '$zone, $city';

  String get platformName =>
      platform.name[0].toUpperCase() + platform.name.substring(1);

  Color get platformColor {
    switch (platform) {
      case DeliveryPlatform.zomato:
        return AppColors.zomato;
      case DeliveryPlatform.zepto:
        return AppColors.zepto;
      case DeliveryPlatform.dunzo:
        return AppColors.dunzo;
      case DeliveryPlatform.swiggy:
        return AppColors.swiggy;
      case DeliveryPlatform.amazon:
        return AppColors.amazon;
      case DeliveryPlatform.blinkit:
        return AppColors.blinkit;
    }
  }

  String get platformInitial => platformName[0].toUpperCase();

  double get weeklyPremium {
    switch (tier) {
      case RiskTier.high:
        return 120.0;
      case RiskTier.medium:
        return 90.0;
      case RiskTier.low:
        return 60.0;
    }
  }

  double get coverageLimit {
    switch (tier) {
      case RiskTier.high:
        return 2500.0;
      case RiskTier.medium:
        return 2240.0;
      case RiskTier.low:
        return 2000.0;
    }
  }

  String get tierDisplayName =>
      '${tier.name[0].toUpperCase()}${tier.name.substring(1)} Risk Plan';

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      platform: DeliveryPlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => DeliveryPlatform.zomato,
      ),
      zone: json['zone'] as String,
      city: json['city'] as String,
      tier: RiskTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => RiskTier.medium,
      ),
      weeklyAvgEarnings: (json['weeklyAvgEarnings'] as num).toDouble(),
      trustScore: (json['trustScore'] as num).toDouble(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'platform': platform.name,
      'zone': zone,
      'city': city,
      'tier': tier.name,
      'weeklyAvgEarnings': weeklyAvgEarnings,
      'trustScore': trustScore,
      'joinedAt': joinedAt.toIso8601String(),
      'profileImagePath': profileImagePath,
    };
  }

  Worker copyWith({
    String? id,
    String? name,
    String? phone,
    DeliveryPlatform? platform,
    String? zone,
    String? city,
    RiskTier? tier,
    double? weeklyAvgEarnings,
    double? trustScore,
    DateTime? joinedAt,
    String? profileImagePath,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      platform: platform ?? this.platform,
      zone: zone ?? this.zone,
      city: city ?? this.city,
      tier: tier ?? this.tier,
      weeklyAvgEarnings: weeklyAvgEarnings ?? this.weeklyAvgEarnings,
      trustScore: trustScore ?? this.trustScore,
      joinedAt: joinedAt ?? this.joinedAt,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
