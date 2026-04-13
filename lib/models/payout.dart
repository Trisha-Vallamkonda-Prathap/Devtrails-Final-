import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'trigger_event.dart';
import '../theme/app_colors.dart';

enum PayoutStatus { pending, accepted, declined, flagged }

class Payout {
  const Payout({
    required this.id,
    required this.workerId,
    required this.zone,
    required this.description,
    required this.triggerType,
    required this.amount,
    required this.status,
    required this.triggeredAt,
    this.settledAt,
    this.transactionId,
  });

  final String id;
  final String workerId;
  final String zone;
  final String description;
  final TriggerType triggerType;
  final double amount;
  final PayoutStatus status;
  final DateTime triggeredAt;
  final DateTime? settledAt;
  final String? transactionId;

  String get triggerDisplayName {
    switch (triggerType) {
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

  String get triggerEmoji {
    switch (triggerType) {
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

  String get formattedAmount =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(amount);

  String get formattedDate => DateFormat('dd MMM, hh:mm a').format(triggeredAt);

  Color get statusColor {
    switch (status) {
      case PayoutStatus.accepted:
        return AppColors.success;
      case PayoutStatus.declined:
        return AppColors.textSoft;
      case PayoutStatus.flagged:
        return AppColors.warning;
      case PayoutStatus.pending:
        return AppColors.primary;
    }
  }

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      zone: json['zone'] as String,
      description: json['description'] as String,
      triggerType: TriggerType.values.firstWhere(
        (t) => t.name == json['triggerType'],
        orElse: () => TriggerType.rain,
      ),
      amount: (json['amount'] as num).toDouble(),
      status: PayoutStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PayoutStatus.pending,
      ),
      triggeredAt: DateTime.parse(json['triggeredAt'] as String),
      settledAt: json['settledAt'] == null
          ? null
          : DateTime.parse(json['settledAt'] as String),
      transactionId: json['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'zone': zone,
      'description': description,
      'triggerType': triggerType.name,
      'amount': amount,
      'status': status.name,
      'triggeredAt': triggeredAt.toIso8601String(),
      'settledAt': settledAt?.toIso8601String(),
      'transactionId': transactionId,
    };
  }

  Payout copyWith({
    String? id,
    String? workerId,
    String? zone,
    String? description,
    TriggerType? triggerType,
    double? amount,
    PayoutStatus? status,
    DateTime? triggeredAt,
    DateTime? settledAt,
    String? transactionId,
  }) {
    return Payout(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      zone: zone ?? this.zone,
      description: description ?? this.description,
      triggerType: triggerType ?? this.triggerType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      settledAt: settledAt ?? this.settledAt,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}
