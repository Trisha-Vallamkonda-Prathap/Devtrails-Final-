import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/notification_tile.dart';

class AlertsScreen extends StatelessWidget {
  AlertsScreen({super.key});

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Heavy Rain Alert',
      'message': 'Avoid delivery in Zone A',
      'time': '2 min ago',
      'color': AppColors.alertBlue,
    },
    {
      'title': 'Heatwave Warning',
      'message': 'Stay hydrated',
      'time': '10 min ago',
      'color': AppColors.alertOrange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];

          return NotificationTile(
            title: n['title'] as String,
            message: n['message'] as String,
            time: n['time'] as String,
            color: n['color'] as Color,
          );
        },
      ),
      backgroundColor: AppColors.pageBackground,
    );
  }
}
