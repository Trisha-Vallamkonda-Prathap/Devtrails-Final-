import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0E6B74);
  static const primaryMid = Color(0xFF1A8A93);
  static const primaryLight = Color(0xFF2DB5C0);
  static const primaryGlow = Color(0xFF52C8D0);
  static const tealLight = Color(0xFFE8F8F9);
  static const tealMid = Color(0xFFC2EEF1);
  static const background = Color(0xFFF0F7F8);
  static const pageBackground = background;
  static const cardBg = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF0D1F24);
  static const darkCard = Color(0xFF1A2F36);
  static const darkBorder = Color(0xFF1A4A54);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const textPrimary = Color(0xFF1A2A2E);
  static const textMid = Color(0xFF4A6367);
  static const textSoft = Color(0xFF8AADB2);
  static const divider = Color(0xFFE8F0F1);
  static const zomato = Color(0xFFE23744);
  static const zepto = Color(0xFF8B5CF6);
  static const dunzo = Color(0xFFF97316);
  static const swiggy = Color(0xFFFC8019);
  static const amazon = Color(0xFFFF9900);
  static const blinkit = Color(0xFFFFD700);

  static Color tierColor(String tier) {
    switch (tier) {
      case 'high':
        return warning;
      case 'low':
        return success;
      default:
        return primary;
    }
  }

  static const List<Color> tealGradient = [
    Color(0xFF1A8A93),
    Color(0xFF2DB5C0),
    Color(0xFF52C8D0),
  ];

  const AppColors._();
}
