import 'package:flutter/material.dart';

class AnimatedWorkerCard extends StatefulWidget {
  const AnimatedWorkerCard({super.key});

  @override
  State<AnimatedWorkerCard> createState() => _AnimatedWorkerCardState();
}

class _AnimatedWorkerCardState extends State<AnimatedWorkerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: const Icon(Icons.delivery_dining, size: 84, color: Colors.white),
    );
  }
}
