import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/payout.dart';
import '../models/worker.dart';
import '../screens/main/main_shell.dart';
import '../theme/app_colors.dart';

class UpiSuccessScreen extends StatefulWidget {
  const UpiSuccessScreen({super.key, required this.payout, required this.worker});

  final Payout payout;
  final Worker worker;

  @override
  State<UpiSuccessScreen> createState() => _UpiSuccessScreenState();
}

class _UpiSuccessScreenState extends State<UpiSuccessScreen> with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future<void>.delayed(const Duration(milliseconds: 400), _contentCtrl.forward);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_contentCtrl);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.95, -0.28),
            end: Alignment(0.95, 0.28),
            colors: AppColors.tealGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _checkCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _checkCtrl.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _contentCtrl,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        children: [
                          const Text('Payout Accepted!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('Transferred to your UPI account', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15)),
                          const SizedBox(height: 24),
                          Text(widget.payout.formattedAmount, style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('${widget.payout.triggerDisplayName} · ${widget.worker.zone}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Text('Transaction ID', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(widget.payout.transactionId ?? 'Pending', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 52),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute<void>(builder: (_) => const MainShell(initialTab: 1)),
                                (_) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            ),
                            child: const Text('Done →'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
