import 'package:flutter/material.dart';

import '../models/worker.dart';

class PlatformBadge extends StatelessWidget {
  final DeliveryPlatform platform;
  final double size;
  final bool showLabel;

  const PlatformBadge({
    super.key,
    required this.platform,
    this.size = 32,
    this.showLabel = false,
  });

  String get _initial => _name[0].toUpperCase();

  String get _name {
    switch (platform) {
      case DeliveryPlatform.zomato:
        return 'Zomato';
      case DeliveryPlatform.zepto:
        return 'Zepto';
      case DeliveryPlatform.dunzo:
        return 'Dunzo';
      case DeliveryPlatform.swiggy:
        return 'Swiggy';
      case DeliveryPlatform.amazon:
        return 'Amazon';
      case DeliveryPlatform.blinkit:
        return 'Blinkit';
    }
  }

  Color get _color {
    switch (platform) {
      case DeliveryPlatform.zomato:
        return const Color(0xFFE23744);
      case DeliveryPlatform.zepto:
        return const Color(0xFF8B5CF6);
      case DeliveryPlatform.dunzo:
        return const Color(0xFFF97316);
      case DeliveryPlatform.swiggy:
        return const Color(0xFFFC8019);
      case DeliveryPlatform.amazon:
        return const Color(0xFFFF9900);
      case DeliveryPlatform.blinkit:
        return const Color(0xFF0C831F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );

    if (!showLabel) {
      return badge;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 8),
        Text(
          _name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2A2E),
          ),
        ),
      ],
    );
  }
}
