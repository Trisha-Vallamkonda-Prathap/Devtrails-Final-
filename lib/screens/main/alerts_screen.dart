import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trigger_event.dart';
import '../../providers/payout_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/ml_premium_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/payout_bottom_sheet.dart';
import '../../widgets/teal_header.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final worker = context.watch<WorkerProvider>().worker;
    final payoutProvider = context.watch<PayoutProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final pending = payoutProvider.pending;

    // Dynamic ML-powered alert copy
    final rainTrigger = weatherProvider.triggers
        .where((t) => t.type == TriggerType.rain)
        .cast<TriggerEvent?>()
        .firstWhere((_) => true, orElse: () => null);
    final rainPct = rainTrigger?.percent ?? 0.0;
    final minutesEstimate =
        rainPct > 0.5 ? ((1.0 - rainPct) / 0.02).toInt().clamp(5, 60) : null;

    final notifications = [
      if (pending != null && worker != null)
        _Notif(
          unread: true,
          type: _NotifType.payout,
          title: 'Payout Ready — Tap to Accept',
          message:
              'Rain crossed threshold in ${worker.zone}. ₹${pending.amount.toInt()} is waiting. Accept in 24 hours or it auto-credits.',
          time: 'Just now',
          onTap: () => showPayoutBottomSheet(context, pending, worker),
        ),
      if (minutesEstimate != null)
        _Notif(
          unread: true,
          type: _NotifType.warning,
          title: 'Conditions Worsening',
          message:
              'AI model predicts rain trigger in ~$minutesEstimate minutes. Consider switching zones or wrapping up deliveries.',
          time: '5 min ago',
        ),
      _Notif(
        unread: true,
        type: _NotifType.success,
        title: 'Payout Credited',
        message:
            '₹175 transferred to your UPI for yesterday\'s heat event in ${worker?.zone ?? 'your zone'}.',
        time: 'Yesterday, 1:45 PM',
      ),
      _Notif(
        unread: false,
        type: _NotifType.info,
        title: 'Weekly Plan Renewed',
        message:
            'Your ${worker?.tierDisplayName ?? 'plan'} (₹${worker?.weeklyPremium.toInt() ?? '--'}) has been auto-renewed for this week.',
        time: 'Mon, 9:00 AM',
      ),
      _Notif(
        unread: false,
        type: _NotifType.trust,
        title: 'Trust Score Updated',
        message:
            'Your trust score is ${worker?.trustScore.toInt() ?? '--'}/100. ${(worker?.trustScore ?? 0) >= 80 ? 'You qualify for fast-track payouts.' : 'Keep going to unlock fast-track payouts.'}',
        time: 'Sun, 8:00 PM',
      ),
      _Notif(
        unread: false,
        type: _NotifType.info,
        title: 'Premium Adjusted by AI',
        message:
            'Your premium was updated based on new zone and weather data. ${rainPct > 0.5 ? 'Rain conditions are above normal this week.' : 'Conditions are stable this week.'}',
        time: 'Last Monday',
      ),
    ];

    final unreadCount = notifications.where((n) => n.unread).length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 130,
          flexibleSpace: FlexibleSpaceBar(
            background: TealHeader(
              bottomPadding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unreadCount > 0
                        ? '$unreadCount unread alerts'
                        : 'All caught up',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
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
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _NotificationTile(notif: notifications[index]),
              childCount: notifications.length,
            ),
          ),
        ),
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

enum _NotifType { payout, warning, success, info, trust }

class _Notif {
  const _Notif({
    required this.unread,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.onTap,
  });

  final bool unread;
  final _NotifType type;
  final String title;
  final String message;
  final String time;
  final VoidCallback? onTap;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notif});
  final _Notif notif;

  IconData get _icon {
    switch (notif.type) {
      case _NotifType.payout:
        return Icons.payments_outlined;
      case _NotifType.warning:
        return Icons.warning_amber_rounded;
      case _NotifType.success:
        return Icons.check_circle_outline;
      case _NotifType.info:
        return Icons.info_outline;
      case _NotifType.trust:
        return Icons.verified_user_outlined;
    }
  }

  Color get _color {
    switch (notif.type) {
      case _NotifType.payout:
        return AppColors.success;
      case _NotifType.warning:
        return AppColors.warning;
      case _NotifType.success:
        return AppColors.success;
      case _NotifType.info:
        return AppColors.info;
      case _NotifType.trust:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: notif.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: notif.unread
              ? Border(left: BorderSide(color: _color, width: 3))
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          notif.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (notif.unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMid,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        notif.time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSoft,
                        ),
                      ),
                      if (notif.onTap != null) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
