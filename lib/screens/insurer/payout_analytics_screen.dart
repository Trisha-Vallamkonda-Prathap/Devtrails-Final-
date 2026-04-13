import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/insurer/mock_data.dart';
import '../../theme/insurer_colors.dart';

class PayoutAnalyticsScreen extends StatelessWidget {
  const PayoutAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        title: const Text(
          'Payout Analytics',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _HeadlineStat(
                  label: 'This month',
                  value: '₹${(1248000 / 100000).toStringAsFixed(1)}L',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeadlineStat(
                  label: 'This year',
                  value: '₹${(15892000 / 100000).toStringAsFixed(1)}L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Payouts by city',
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500000,
                    getDrawingHorizontalLine: (value) => const FlLine(color: InsurerColors.grid, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${(value / 100000).toInt()}L',
                          style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= mockPayoutByCity.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              mockPayoutByCity[index].city.substring(0, 3),
                              style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (var i = 0; i < mockPayoutByCity.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: mockPayoutByCity[i].amount.toDouble(),
                            color: i.isEven ? InsurerColors.accent : InsurerColors.warning,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Trigger type mix',
            child: SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 52,
                  sections: [
                    for (var i = 0; i < mockTriggerBreakdown.length; i++)
                      PieChartSectionData(
                        value: mockTriggerBreakdown[i].amount.toDouble(),
                        title: '${mockTriggerBreakdown[i].label}\n${mockTriggerBreakdown[i].amount}%',
                        radius: 72,
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        color: [InsurerColors.accent, InsurerColors.warning, InsurerColors.success, Colors.grey, Colors.blueGrey][i % 5],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: '6 month payout trend',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 250000,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: InsurerColors.grid, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${(value / 100000).toInt()}L',
                          style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= mockMonthlyPayoutTrend.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            mockMonthlyPayoutTrend[index].month,
                            style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: mockMonthlyPayoutTrend.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.amount.toDouble());
                      }).toList(),
                      isCurved: true,
                      barWidth: 3,
                      color: InsurerColors.warning,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: InsurerColors.warning.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InsurerColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InsurerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: InsurerColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HeadlineStat extends StatelessWidget {
  const _HeadlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InsurerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InsurerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: InsurerColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
