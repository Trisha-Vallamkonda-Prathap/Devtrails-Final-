import 'package:flutter/material.dart';

import '../../theme/insurer_colors.dart';

class ComingSoonShell extends StatelessWidget {
  const ComingSoonShell({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: InsurerColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: InsurerColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: InsurerColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Prototype shell ready',
              style: TextStyle(color: InsurerColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                color: InsurerColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}