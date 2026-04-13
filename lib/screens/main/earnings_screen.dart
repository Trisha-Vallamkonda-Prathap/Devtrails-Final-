import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/payout_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/earnings_chart.dart';
import '../../widgets/payout_history_tile.dart';
import '../../widgets/teal_header.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payoutProvider = context.watch<PayoutProvider>();
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final topInset = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: topInset + 220,
          flexibleSpace: FlexibleSpaceBar(
            background: TealHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Earnings Protected 💰', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Payout Received:', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                        Text(money.format(payoutProvider.totalProtected), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
                        Text('This Week: ${money.format(payoutProvider.thisWeek)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  SizedBox(height: 12),
                  _BreakRow(name: 'Rain', amount: '₹500', pct: 0.64, color: AppColors.primaryLight),
                  SizedBox(height: 8),
                  _BreakRow(name: 'Traffic', amount: '₹300', pct: 0.38, color: AppColors.info),
                  SizedBox(height: 8),
                  _BreakRow(name: 'Heatwave', amount: '₹280', pct: 0.36, color: AppColors.warning),
                ]),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Earnings Protected', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
                    EarningsChart(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'You recovered ', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                            TextSpan(text: '35%', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
                            TextSpan(text: ' of lost income this week.', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payout History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (payoutProvider.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No payouts yet.'),
                      )
                    else
                      ...payoutProvider.history.asMap().entries.map((entry) {
                        final i = entry.key;
                        final payout = entry.value;
                        return Column(
                          children: [
                            PayoutHistoryTile(payout: payout),
                            if (i != payoutProvider.history.length - 1)
                              const Divider(color: AppColors.divider),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _BreakRow extends StatefulWidget {
  const _BreakRow({required this.name, required this.amount, required this.pct, required this.color});

  final String name;
  final String amount;
  final double pct;
  final Color color;

  @override
  State<_BreakRow> createState() => _BreakRowState();
}

class _BreakRowState extends State<_BreakRow> {
  double width = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => width = widget.pct));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.name, style: const TextStyle(fontSize: 13, color: AppColors.textMid), overflow: TextOverflow.ellipsis)),
            Text(widget.amount, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: constraints.maxWidth * width,
                  decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
