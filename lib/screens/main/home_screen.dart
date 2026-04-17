import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/trigger_event.dart';
import '../../models/worker.dart';
import '../../providers/location_provider.dart';
import '../../providers/payout_provider.dart';
import '../../providers/policy_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/ml_premium_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/platform_badge.dart';
import '../../widgets/trigger_monitor_card.dart';
import '../../widgets/trust_score_badge.dart';
import '../../widgets/zone_recommender_card.dart';
import '../city_picker_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSwitchTab});
  final ValueChanged<int> onSwitchTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NumberFormat money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String? _activeZone;
  WeatherProvider? _weatherProvider;
  late AnimationController _pulseCtrl;
  late AnimationController _signalCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _signalAnim;
  bool _updatingLocation = false;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _subtitle(Worker worker, bool hasRisk, TriggerEvent? rain,
      TriggerEvent? heat, TriggerEvent? aqi) {
    if (hasRisk) {
      if (rain != null && rain.isTriggered) {
        return 'Heavy rain detected in ${worker.zone}. Your coverage is active.';
      }
      if (heat != null && heat.isTriggered) {
        return 'Extreme heat alert in your zone. Stay safe out there.';
      }
      if (aqi != null && aqi.isTriggered) {
        return 'Air quality is poor in ${worker.zone}. Take precautions today.';
      }
      if (worker.tier == RiskTier.high) {
        return 'High risk conditions detected in your zone. We\'ve got you covered.';
      }
      return 'We\'ve detected a possible risk nearby. Please review.';
    }

    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) return 'Early start today. Your coverage is active and ready.';
    if (h >= 9 && h < 12) return 'Hope your deliveries are going smoothly this morning.';
    if (h >= 12 && h < 14) return 'Midday check-in — your earnings are protected.';
    if (h >= 14 && h < 17) return 'Afternoon surge ahead. You\'re fully covered in ${worker.zone}.';
    if (h >= 17 && h < 20) return 'Peak hours in ${worker.zone}. Stay safe and earn well.';
    return 'Late shift coverage active. Drive safe out there.';
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _signalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _signalAnim =
        CurvedAnimation(parent: _signalCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindZoneAndSync();
      _signalCtrl.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextWeather = context.read<WeatherProvider>();
    if (!identical(_weatherProvider, nextWeather)) {
      _weatherProvider?.removeListener(_onWeatherChanged);
      _weatherProvider = nextWeather;
      _weatherProvider?.addListener(_onWeatherChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bindZoneAndSync();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _signalCtrl.dispose();
    _weatherProvider?.removeListener(_onWeatherChanged);
    super.dispose();
  }

  void _bindZoneAndSync() {
    final worker = context.read<WorkerProvider>().worker;
    if (worker == null) return;
    // BUG FIX 2: always read zone from WorkerProvider (single source of truth)
    final zone = worker.fullZone;
    if (_activeZone != zone) {
      _activeZone = zone;
      context.read<WeatherProvider>().fetch(zone);
    }
    final weather = context.read<WeatherProvider>();
    context.read<PayoutProvider>().syncAutoTrigger(worker, weather.triggers);
  }

  void _onWeatherChanged() {
    if (!mounted) return;
    final worker = context.read<WorkerProvider>().worker;
    if (worker == null) return;
    context.read<PayoutProvider>().syncAutoTrigger(
          worker,
          context.read<WeatherProvider>().triggers,
        );
  }

  /// BUG FIX 5: refresh ONLY re-fetches GPS and updates location state.
  /// It does NOT silently override the worker's current zone.
  /// Zone is only updated if the worker explicitly confirms via the map flow.
  Future<void> _updateLocation() async {
    setState(() => _updatingLocation = true);
    final locProvider = context.read<LocationProvider>();

    // Fetch fresh GPS — updates LocationProvider internal state only
    await locProvider.fetchLocation();

    if (!mounted) return;

    // Show spoof / risk warnings but do NOT auto-switch zone
    if (locProvider.spoofDetected) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(locProvider.errorMessage ??
            'Location inconsistency detected. Please review.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    } else if (locProvider.errorMessage != null &&
        locProvider.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(locProvider.errorMessage!),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }

    // Re-sync weather for current worker zone (zone has NOT changed here)
    _bindZoneAndSync();

    setState(() => _updatingLocation = false);
  }

  List<Color> get _headerGradient {
    final worker = context.read<WorkerProvider>().worker;
    if (worker == null) return AppColors.tealGradient;
    switch (worker.tier) {
      case RiskTier.high:
        return const [Color(0xFF7A1515), Color(0xFF9B2020), Color(0xFFB83232)];
      case RiskTier.medium:
        return AppColors.tealGradient;
      case RiskTier.low:
        return const [
          Color(0xFF145A2E),
          Color(0xFF1A8A44),
          Color(0xFF22B05A),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = context.watch<WorkerProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final payoutProvider = context.watch<PayoutProvider>();
    final policyProvider = context.watch<PolicyProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final worker = workerProvider.worker;

    if (worker == null) {
      return const Center(child: CircularProgressIndicator());
    }

    TriggerEvent? find(TriggerType t) {
      for (final e in weatherProvider.triggers) {
        if (e.type == t) return e;
      }
      return null;
    }

    final rain = find(TriggerType.rain);
    final heat = find(TriggerType.heat);
    final aqi = find(TriggerType.aqi);
    final topInset = MediaQuery.of(context).padding.top;

    final breakdown = MLPremiumEngine.calculate(
      worker: worker,
      payoutHistory: payoutProvider.history,
      currentRainPercent: rain?.percent ?? 0.0,
    );

    final hasRisk = worker.tier == RiskTier.high ||
        locationProvider.spoofDetected ||
        (rain?.isTriggered ?? false) ||
        (heat?.isTriggered ?? false) ||
        (aqi?.isTriggered ?? false);

    final subtitleText = _subtitle(worker, hasRisk, rain, heat, aqi);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: topInset + 330,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _headerGradient,
                  begin: const Alignment(-0.8, -1.0),
                  end: const Alignment(0.8, 1.0),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 20,
                16,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header bar ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute<void>(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: AvatarWidget(
                            name: worker.name,
                            size: 42,
                            imagePath: worker.profileImagePath,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$_greeting, ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      worker.name.split(' ').first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitleText,
                                maxLines: 2,
                                style: TextStyle(
                                  color: hasRisk
                                      ? Colors.amber.shade200
                                      : Colors.white
                                          .withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: hasRisk
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            PlatformBadge(
                                platform: worker.platform, size: 24),
                            const SizedBox(height: 4),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () => widget.onSwitchTab(3),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                if (payoutProvider.hasPending)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Update Location pill ──
                  // BUG FIX 2: displays worker.fullZone — always the authoritative value
                  GestureDetector(
                    onTap: _updatingLocation ? null : _updateLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _updatingLocation
                              ? const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.my_location,
                                  color: Colors.white, size: 12),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _updatingLocation
                                  ? 'Updating location...'
                                  : '${worker.fullZone}  •  Tap to refresh',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Weather gauges ──
                  if (weatherProvider.loading)
                    Shimmer.fromColors(
                      baseColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor:
                          Colors.white.withValues(alpha: 0.35),
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    _WeatherGaugesRow(
                      rain: rain,
                      heat: heat,
                      aqi: aqi,
                      signalAnim: _signalAnim,
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (locationProvider.spoofDetected)
                _SubtleRiskBanner(
                  message:
                      'We\'ve detected a possible location inconsistency. Your access is not affected.',
                ),
              if (worker.tier == RiskTier.high) _HighRiskBanner(),
              if (rain != null && rain.isTriggered)
                _WeatherRiskBanner(
                  icon: Icons.water_drop,
                  color: AppColors.info,
                  message:
                      'Rain trigger active in ${worker.zone}. Payouts are being processed.',
                ),
              if (heat != null && heat.isTriggered)
                _WeatherRiskBanner(
                  icon: Icons.thermostat,
                  color: AppColors.warning,
                  message:
                      'Heat threshold crossed in your zone. Income protection is active.',
                ),
              if (aqi != null && aqi.isTriggered)
                _WeatherRiskBanner(
                  icon: Icons.air,
                  color: AppColors.danger,
                  message:
                      'Air quality alert in ${worker.zone}. Please take necessary precautions.',
                ),
              const SizedBox(height: 4),
              _MLIntelligenceCard(
                breakdown: breakdown,
                worker: worker,
                signalAnim: _signalAnim,
                pulseAnim: _pulseAnim,
              ),
              const SizedBox(height: 12),
              const ZoneRecommenderCard(),
              const SizedBox(height: 12),
              _PremiumTrustCard(
                worker: worker,
                policyProvider: policyProvider,
                onSwitchTab: widget.onSwitchTab,
              ),
              const SizedBox(height: 12),
              _EarningsStatsRow(
                  payoutProvider: payoutProvider, money: money),
              const SizedBox(height: 12),
              _ClaimProbabilityStrip(breakdown: breakdown),
              const SizedBox(height: 12),
              TriggerMonitorCard(triggers: weatherProvider.triggers),
              const SizedBox(height: 90),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Subtle risk / inconsistency banner ───────────────────────────────────────
class _SubtleRiskBanner extends StatelessWidget {
  const _SubtleRiskBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherRiskBanner extends StatelessWidget {
  const _WeatherRiskBanner({
    required this.icon,
    required this.color,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighRiskBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFB22222), size: 15),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'High flood risk zone — disruptions more likely this week. Your coverage limit has been raised.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB22222),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherGaugesRow extends StatelessWidget {
  const _WeatherGaugesRow({
    required this.rain,
    required this.heat,
    required this.aqi,
    required this.signalAnim,
  });

  final TriggerEvent? rain;
  final TriggerEvent? heat;
  final TriggerEvent? aqi;
  final Animation<double> signalAnim;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GaugeCell(
            label: 'Rain',
            value: rain != null ? '${rain!.currentValue}mm' : '--',
            percent: rain?.percent ?? 0.0,
            color: AppColors.info,
            icon: Icons.water_drop_outlined,
            triggered: rain?.isTriggered ?? false,
            anim: signalAnim,
          ),
        ),
        Expanded(
          child: _GaugeCell(
            label: 'Heat',
            value: heat != null ? '${heat!.currentValue}°C' : '--',
            percent: heat?.percent ?? 0.0,
            color: AppColors.warning,
            icon: Icons.thermostat,
            triggered: heat?.isTriggered ?? false,
            anim: signalAnim,
          ),
        ),
        Expanded(
          child: _GaugeCell(
            label: 'AQI',
            value: aqi != null ? '${aqi!.currentValue.toInt()}' : '--',
            percent: aqi?.percent ?? 0.0,
            color: AppColors.danger,
            icon: Icons.air,
            triggered: aqi?.isTriggered ?? false,
            anim: signalAnim,
          ),
        ),
        Expanded(
          child: _GaugeCell(
            label: 'Traffic',
            value: 'High',
            percent: 0.72,
            color: AppColors.warning,
            icon: Icons.directions_car_outlined,
            triggered: false,
            anim: signalAnim,
          ),
        ),
      ],
    );
  }
}

class _GaugeCell extends StatelessWidget {
  const _GaugeCell({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
    required this.triggered,
    required this.anim,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;
  final IconData icon;
  final bool triggered;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
          border: triggered
              ? Border.all(
                  color: AppColors.danger.withValues(alpha: 0.7))
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(
                painter: _ArcGaugePainter(
                  value: percent * anim.value,
                  color: color,
                  triggered: triggered,
                ),
                child: Center(
                    child: Icon(icon, size: 14, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter(
      {required this.value, required this.color, required this.triggered});
  final double value;
  final Color color;
  final bool triggered;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 3;
    const startAngle = math.pi * 0.7;
    const sweepMax = math.pi * 1.6;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle, sweepMax, false, trackPaint);
    if (value > 0) {
      final fillPaint = Paint()
        ..color = triggered ? AppColors.danger : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          startAngle,
          sweepMax * value.clamp(0.0, 1.0),
          false,
          fillPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.value != value || old.triggered != triggered;
}

// ── ML Intelligence Card ──────────────────────────────────────────────────────
class _MLIntelligenceCard extends StatelessWidget {
  const _MLIntelligenceCard({
    required this.breakdown,
    required this.worker,
    required this.signalAnim,
    required this.pulseAnim,
  });

  final PremiumBreakdown breakdown;
  final Worker worker;
  final Animation<double> signalAnim;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGlow,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlow
                              .withValues(alpha: pulseAnim.value * 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('AI RISK ENGINE',
                    style: TextStyle(
                        color: AppColors.primaryGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    breakdown.riskLabel,
                    style: TextStyle(
                      color: breakdown.zoneScore > 0.70
                          ? AppColors.danger
                          : breakdown.zoneScore > 0.50
                              ? AppColors.warning
                              : AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${breakdown.finalPremium.toInt()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('/week',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12)),
                ),
                const Spacer(),
                if (breakdown.isCheaper)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '−₹${breakdown.savingsOrCost.abs().toInt()} saved',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+₹${breakdown.savingsOrCost.abs().toInt()} risk',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _SignalBar(
                    label: 'Zone flood risk',
                    value: breakdown.zoneScore,
                    color: breakdown.zoneScore > 0.70
                        ? AppColors.danger
                        : AppColors.warning,
                    anim: signalAnim),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Season pressure',
                    value: ((breakdown.seasonalMultiplier - 0.8) / 0.6)
                        .clamp(0.0, 1.0),
                    color: AppColors.info,
                    anim: signalAnim),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Claim history',
                    value: 1.0 - breakdown.claimRatio,
                    color: AppColors.success,
                    anim: signalAnim,
                    isPositive: true),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Live rain proximity',
                    value: breakdown.proximityAdjustmentPercent.abs() /
                        18.0,
                    color: AppColors.primaryLight,
                    anim: signalAnim),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Platform demand spike',
                    value:
                        breakdown.platformAdjustmentPercent.abs() / 10.0,
                    color: AppColors.warning,
                    anim: signalAnim),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Trust score bonus',
                    value: breakdown.trustBonusPercent.abs() / 4.0,
                    color: AppColors.success,
                    anim: signalAnim,
                    isPositive: true),
                const SizedBox(height: 7),
                _SignalBar(
                    label: 'Zone × season compound',
                    value: (breakdown.interactionTermPercent.abs() / 15.0)
                        .clamp(0.0, 1.0),
                    color: AppColors.danger,
                    anim: signalAnim),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.darkBorder),
          if (breakdown.canSaveByMoving && breakdown.neighbourZone != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: 'Move to ${breakdown.neighbourZone} ',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12)),
                      TextSpan(
                          text:
                              '→ save ₹${breakdown.zoneSavingsByMoving.toInt()}/week',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ])),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4-WEEK FORECAST',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                _FourWeekForecastBar(
                    forecast: breakdown.fourWeekForecast),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  const _SignalBar({
    required this.label,
    required this.value,
    required this.color,
    required this.anim,
    this.isPositive = false,
  });
  final String label;
  final double value;
  final Color color;
  final Animation<double> anim;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: (value * anim.value).clamp(0.0, 1.0),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPositive
                ? '+${(value * 100 * anim.value).toInt()}%'
                : '${(value * 100 * anim.value).toInt()}%',
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FourWeekForecastBar extends StatelessWidget {
  const _FourWeekForecastBar({required this.forecast});
  final List<double> forecast;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    final maxVal = forecast.reduce(math.max);
    final minVal = forecast.reduce(math.min);
    final labels = ['W1', 'W2', 'W3', 'W4'];
    return Row(
      children: List.generate(forecast.length, (i) {
        final val = forecast[i];
        final hf = maxVal == minVal
            ? 0.5
            : (val - minVal) / (maxVal - minVal);
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.3 + hf * 0.7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow
                          .withValues(alpha: 0.3 + hf * 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text('₹${val.toInt()}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w600)),
              Text(labels[i],
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 7)),
            ],
          ),
        );
      }),
    );
  }
}

// ── Premium + Trust Card ──────────────────────────────────────────────────────
class _PremiumTrustCard extends StatelessWidget {
  const _PremiumTrustCard({
    required this.worker,
    required this.policyProvider,
    required this.onSwitchTab,
  });
  final Worker worker;
  final PolicyProvider policyProvider;
  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tierColor(worker.tier.name)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              worker.tierDisplayName,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tierColor(
                                      worker.tier.name)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Active',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Consumer<PolicyProvider>(
                        builder: (_, pProv, __) {
                          final premium =
                              pProv.activePolicy?.weeklyPremium ??
                                  worker.weeklyPremium;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('₹${premium.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                              const SizedBox(width: 4),
                              const Text('/week',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSoft)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TRUST SCORE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSoft,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text('${worker.trustScore.toInt()}/100',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    TrustScoreBadge(score: worker.trustScore),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onSwitchTab(2),
                    icon: const Icon(Icons.shield_outlined, size: 14),
                    label: const Text('View plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMid,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (_) =>
                              const CityPickerScreen(isOnboarding: false),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on_outlined, size: 14),
                    label: const Text('Change zone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMid,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsStatsRow extends StatelessWidget {
  const _EarningsStatsRow(
      {required this.payoutProvider, required this.money});
  final PayoutProvider payoutProvider;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.currency_rupee,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(height: 8),
                const Text('This Week',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSoft)),
                Text(money.format(payoutProvider.thisWeek),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const Text('protected',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.trending_up,
                      color: AppColors.success, size: 16),
                ),
                const SizedBox(height: 8),
                const Text('Total Saved',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSoft)),
                Text(money.format(payoutProvider.totalProtected),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const Text('all time',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSoft)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClaimProbabilityStrip extends StatelessWidget {
  const _ClaimProbabilityStrip({required this.breakdown});
  final PremiumBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final prob = breakdown.claimProbability;
    final pct = (prob * 100).toInt();
    final color = prob < 0.30
        ? AppColors.success
        : prob < 0.60
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(Icons.analytics_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Claim probability this week',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(width: 6),
                    Text(breakdown.claimProbabilityLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('At risk',
                  style:
                      TextStyle(fontSize: 9, color: AppColors.textSoft)),
              Text('₹${breakdown.earningsAtRisk.toInt()}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}