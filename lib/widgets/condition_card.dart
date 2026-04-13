import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConditionCard extends StatelessWidget {
  const ConditionCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.statusColor,
  });

  final String emoji;
  final String label;
  final String value;
  final Color statusColor;

  String get _label {
    if (statusColor == AppColors.danger) {
      return 'TRIGGERED';
    }
    if (statusColor == AppColors.warning) {
      return 'NEAR';
    }
    return 'CLEAR';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 98;
        return Container(
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
                  SizedBox(width: compact ? 3 : 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 6,
                  vertical: compact ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: compact ? 8 : 9,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
