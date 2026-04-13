import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';

class NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final Color color;

  const NotificationTile({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(title, style: AppTextStyles.title),
        subtitle: Text(message, style: AppTextStyles.body),
        trailing: Text(time, style: AppTextStyles.caption),
      ),
    );
  }
}
