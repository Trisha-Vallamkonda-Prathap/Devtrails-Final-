import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = const [
      FlSpot(0, 175),
      FlSpot(1, 390),
      FlSpot(2, 120),
      FlSpot(3, 324),
      FlSpot(4, 280),
      FlSpot(5, 0),
      FlSpot(6, 0),
    ];

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.primaryLight,
              barWidth: 2.5,
              isCurved: true,
              curveSmoothness: 0.35,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                  radius: spot.y > 0 ? 4 : 0,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primaryLight,
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 100,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                  if (v.toInt() < 0 || v.toInt() > 6) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[v.toInt()],
                    style: const TextStyle(fontSize: 10, color: AppColors.textSoft),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
