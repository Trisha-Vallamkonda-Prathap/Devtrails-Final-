import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/insurer/mock_data.dart';
import '../../providers/role_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/worker_provider.dart';
import '../../theme/insurer_colors.dart';
import '../../utils/auth_utils.dart';

class InsurerHomeScreen extends StatefulWidget {
  const InsurerHomeScreen({super.key});

  @override
  State<InsurerHomeScreen> createState() => _InsurerHomeScreenState();
}

class _InsurerHomeScreenState extends State<InsurerHomeScreen> {
  bool _requestedTriggerFeed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedTriggerFeed) {
      return;
    }
    _requestedTriggerFeed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WeatherProvider>().fetch('Kurla, Mumbai');
    });
  }

  Future<void> _showLogoutDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: InsurerColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log out of GigShield Insurer?',
          style: TextStyle(
            color: InsurerColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'You will need to verify your phone number again.',
          style: TextStyle(color: InsurerColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: InsurerColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthUtils.logout(
                context: context,
                roleProvider: context.read<RoleProvider>(),
                workerProvider: context.read<WorkerProvider>(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: InsurerColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        title: const Text(
          'Insurer Overview',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: InsurerColors.textPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            children: const [
              _PartnerCard(
                platformName: 'Zomato',
                activeWorkerCount: '2,340 active workers',
                logoBackgroundColor: Color(0xFFE23744),
                logoTextColor: Colors.white,
                logoText: 'Zomato',
              ),
              _PartnerCard(
                platformName: 'Dunzo',
                activeWorkerCount: '890 active workers',
                logoBackgroundColor: Color(0xFF6C3FC5),
                logoTextColor: Colors.white,
                logoText: 'dunzo',
              ),
              _PartnerCard(
                platformName: 'Blinkit',
                activeWorkerCount: '1,120 active workers',
                logoBackgroundColor: Color(0xFFF8CC1B),
                logoTextColor: Color(0xFF1A1A1A),
                logoText: 'blinkit',
              ),
              _PartnerCard(
                platformName: 'Amazon',
                activeWorkerCount: '3,210 active workers',
                logoBackgroundColor: Color(0xFF131921),
                logoTextColor: Color(0xFFFF9900),
                logoText: 'amazon',
                showAmazonSmile: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InsurerColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: InsurerColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payout breakdown by city',
                  style: TextStyle(color: InsurerColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ...mockPayoutByCity.map((entry) {
                  final maxAmount = mockPayoutByCity.first.amount.toDouble();
                  final width = (entry.amount / maxAmount).clamp(0.08, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.city, style: const TextStyle(color: InsurerColors.textPrimary, fontSize: 13)),
                            Text('₹${(entry.amount / 100000).toStringAsFixed(1)}L', style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: width,
                            backgroundColor: InsurerColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(InsurerColors.accent),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _premiumEngineSection(),
          const SizedBox(height: 16),
          Consumer<WeatherProvider>(
            builder: (_, weatherProvider, __) => _liveTriggerSection(weatherProvider),
          ),
        ],
      ),
    );
  }

  Widget _premiumEngineSection() {
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
          Row(
            children: [
              const Icon(Icons.auto_graph, color: InsurerColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Dynamic Premium Engine',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InsurerColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: InsurerColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: InsurerColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _MlStatCell('Avg premium', '₹94', 'across all workers'),
              _MlStatCell('Discounts given', '23', 'low-risk workers'),
              _MlStatCell('Surcharges', '8', 'high-claim workers'),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: InsurerColors.border),
          const SizedBox(height: 10),
          const Text(
            'ACTIVE PRICE FACTORS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: InsurerColors.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _mlFactorRow('Monsoon season', 'Jul-Aug peak', '+35%', InsurerColors.accent),
          _mlFactorRow('Mumbai/Delhi zones', 'High flood score', '+18%', InsurerColors.warning),
          _mlFactorRow('Low-claim workers', '23 workers', '-10%', InsurerColors.success),
        ],
      ),
    );
  }

  Widget _mlFactorRow(String factor, String detail, String impact, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              factor,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: InsurerColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: InsurerColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            impact,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _liveTriggerSection(WeatherProvider weatherProvider) {
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
          const Text(
            'Live Trigger Monitor',
            style: TextStyle(color: InsurerColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (weatherProvider.triggers.isEmpty)
            const Text(
              'Waiting for live trigger feed...',
              style: TextStyle(color: InsurerColors.textSecondary, fontSize: 12),
            )
          else
            ...weatherProvider.triggers.map(
              (trigger) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(trigger.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trigger.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: InsurerColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      trigger.statusLabel,
                      style: TextStyle(
                        color: trigger.isTriggered ? InsurerColors.accent : InsurerColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MlStatCell extends StatelessWidget {
  const _MlStatCell(this.label, this.value, this.sub);

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: InsurerColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: InsurerColors.textSecondary)),
          Text(sub, style: const TextStyle(fontSize: 10, color: InsurerColors.textSecondary), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.platformName,
    required this.activeWorkerCount,
    required this.logoBackgroundColor,
    required this.logoTextColor,
    required this.logoText,
    this.showAmazonSmile = false,
  });

  final String platformName;
  final String activeWorkerCount;
  final Color logoBackgroundColor;
  final Color logoTextColor;
  final String logoText;
  final bool showAmazonSmile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InsurerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InsurerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: logoBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      logoText,
                      style: TextStyle(
                        color: logoTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (showAmazonSmile)
                      Positioned(
                        bottom: 4,
                        child: SizedBox(
                          width: 32,
                          height: 7,
                          child: CustomPaint(painter: _AmazonSmilePainter()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            activeWorkerCount,
            style: const TextStyle(
              color: InsurerColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _AmazonSmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9900)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.5, size.height, size.width - 2, size.height * 0.45);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}