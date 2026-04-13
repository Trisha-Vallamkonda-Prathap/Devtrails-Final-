import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payout.dart';
import '../models/worker.dart';
import '../providers/payout_provider.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';
import 'upi_success_screen.dart';

class PayoutBottomSheet extends StatefulWidget {
  const PayoutBottomSheet({
    super.key,
    required this.payout,
    required this.worker,
  });

  final Payout payout;
  final Worker worker;

  @override
  State<PayoutBottomSheet> createState() => _PayoutBottomSheetState();
}

class _PayoutBottomSheetState extends State<PayoutBottomSheet> {
  bool _processing = false;

  Future<void> _decline() async {
    context.read<PayoutProvider>().decline(widget.payout.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payout declined. Data saved.')),
    );
  }

  Future<void> _accept() async {
    setState(() => _processing = true);
    final ok = await context.read<PayoutProvider>().accept(widget.payout.id);
    if (!mounted) {
      return;
    }
    setState(() => _processing = false);
    if (ok) {
      final accepted = context.read<PayoutProvider>().history.first;
      Navigator.pop(context);
      Navigator.push(
        context,
        CupertinoPageRoute<void>(
          builder: (_) => UpiSuccessScreen(payout: accepted, worker: widget.worker),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, safeBottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.payout.amount),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) {
              return Column(
                children: [
                  const Text('🌧️', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  const Text('Disruption Detected!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(widget.worker.fullZone, style: const TextStyle(fontSize: 14, color: AppColors.textSoft)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('Payout Amount', style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
                        Text('₹${v.toInt()}', style: const TextStyle(fontSize: 44, color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Heavy rain crossed threshold in your zone.\nYour earnings were impacted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMid),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text('Trust Score 94/100 · Auto-approved', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _decline,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: AppColors.textMid,
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'Accept Payout ✓',
                  isLoading: _processing,
                  onPressed: _processing ? null : _accept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showPayoutBottomSheet(BuildContext context, Payout payout, Worker worker) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PayoutBottomSheet(payout: payout, worker: worker),
  );
}
