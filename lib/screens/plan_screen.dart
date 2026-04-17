import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/policy_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'subscription_payment_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final policy = context.watch<PolicyProvider>().policy;

    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      backgroundColor: AppColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Premium: Rs ${policy?.weeklyPremium ?? 120}', style: AppTextStyles.body),
                    const SizedBox(height: 10),
                    Text('Coverage: Rs ${policy?.coverageLimit ?? 10000}', style: AppTextStyles.body),
                    const SizedBox(height: 10),
                    Text('Status: ${policy?.status ?? 'Inactive'}', style: policy?.isActive == true ? AppTextStyles.success : AppTextStyles.error),
                    if (policy?.endDate != null) ...[
                      const SizedBox(height: 10),
                      Text('Expires: ${policy!.endDate.toString().split(' ')[0]}', style: AppTextStyles.body),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to payment screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionPaymentScreen(
                      tier: 'Standard', // You can make this dynamic
                      premium: policy?.weeklyPremium ?? 120.0,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Pay Weekly Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
