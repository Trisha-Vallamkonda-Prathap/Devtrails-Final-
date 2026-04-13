import 'package:flutter/material.dart';
import 'package:gigshield/models/worker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class UserStatsCard extends StatelessWidget {
  final Worker worker;

  const UserStatsCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${worker.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(worker.platformName),
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Location: ${worker.fullZone}'),
                Text('Avg. Weekly: ₹${worker.weeklyAvgEarnings}'),
              ],
            ),
            const SizedBox(height: 16),
            Text('Trust Score: ${worker.trustScore}/100'),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: worker.trustScore / 100,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.green,
              barRadius: const Radius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
