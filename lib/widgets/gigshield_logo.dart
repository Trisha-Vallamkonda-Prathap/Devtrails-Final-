import 'dart:math' as math;

import 'package:flutter/material.dart';

class GigShieldLogo extends StatelessWidget {
  final double size;
  final Color color;

  const GigShieldLogo({
    super.key,
    this.size = 48,
    this.color = const Color(0xFF0E6B74),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(color: color),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  const _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.97);
    shieldPath.lineTo(w * 0.08, h * 0.55);
    shieldPath.quadraticBezierTo(w * 0.04, h * 0.18, w * 0.04, h * 0.15);
    shieldPath.quadraticBezierTo(w * 0.04, h * 0.06, w * 0.14, h * 0.05);
    shieldPath.lineTo(w * 0.5, h * 0.02);
    shieldPath.lineTo(w * 0.86, h * 0.05);
    shieldPath.quadraticBezierTo(w * 0.96, h * 0.06, w * 0.96, h * 0.15);
    shieldPath.quadraticBezierTo(w * 0.96, h * 0.18, w * 0.92, h * 0.55);
    shieldPath.close();
    canvas.drawPath(shieldPath, paint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.90);
    innerPath.lineTo(w * 0.14, h * 0.54);
    innerPath.quadraticBezierTo(w * 0.10, h * 0.22, w * 0.10, h * 0.19);
    innerPath.quadraticBezierTo(w * 0.10, h * 0.13, w * 0.19, h * 0.12);
    innerPath.lineTo(w * 0.5, h * 0.09);
    innerPath.lineTo(w * 0.81, h * 0.12);
    innerPath.quadraticBezierTo(w * 0.90, h * 0.13, w * 0.90, h * 0.19);
    innerPath.quadraticBezierTo(w * 0.90, h * 0.22, w * 0.86, h * 0.54);
    innerPath.close();
    canvas.drawPath(innerPath, innerPaint);

    final gPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 0.47, h * 0.48);
    final radius = w * 0.22;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.20,
      math.pi * 1.65,
      false,
      gPaint,
    );

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowY = h * 0.57;
    final arrowStartX = w * 0.47;
    final arrowEndX = w * 0.80;

    final shaftPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(arrowStartX, arrowY),
      Offset(arrowEndX - w * 0.06, arrowY),
      shaftPaint,
    );

    final arrowHead = Path();
    arrowHead.moveTo(arrowEndX, arrowY);
    arrowHead.lineTo(arrowEndX - w * 0.12, arrowY - w * 0.08);
    arrowHead.lineTo(arrowEndX - w * 0.12, arrowY + w * 0.08);
    arrowHead.close();
    canvas.drawPath(arrowHead, arrowPaint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}

class AnimatedGigShieldLogo extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedGigShieldLogo({
    super.key,
    this.size = 80,
    this.color = Colors.white,
  });

  @override
  State<AnimatedGigShieldLogo> createState() => _AnimatedGigShieldLogoState();
}

class _AnimatedGigShieldLogoState extends State<AnimatedGigShieldLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GigShieldLogo(size: widget.size, color: widget.color),
    );
  }
}
