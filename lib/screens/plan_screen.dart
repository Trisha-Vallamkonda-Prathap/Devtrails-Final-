import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Weekly Premium: Rs 120', style: AppTextStyles.body),
                SizedBox(height: 10),
                Text('Coverage: Rs 10,000', style: AppTextStyles.body),
                SizedBox(height: 10),
                Text('Status: Active', style: AppTextStyles.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
