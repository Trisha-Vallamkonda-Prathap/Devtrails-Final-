import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/worker.dart';
import '../../providers/role_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/risk_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/platform_badge.dart';
import 'city_picker_screen.dart';
import 'risk_reveal_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _name = '';
  DeliveryPlatform? _platform;
  double _earnings = 5000;
  String? _imagePath;

  bool get _canContinue => _name.trim().isNotEmpty && _platform != null;

  Future<void> _continue() async {
    final selectedZone = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute<Map<String, dynamic>>(
        builder: (_) => const CityPickerScreen(isOnboarding: true),
      ),
    );
    if (selectedZone == null || !mounted) return;

    final zone = selectedZone['zone'] as String;
    final city = selectedZone['city'] as String;
    final tier = RiskEngine.getTier(zone, city: city);
    final worker = Worker(
      id: 'W-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.trim(),
      phone: '9999999999',
      platform: _platform!,
      zone: zone,
      city: city,
      tier: tier,
      weeklyAvgEarnings: _earnings,
      trustScore: 94,
      joinedAt: DateTime.now(),
      profileImagePath: _imagePath,
    );

    await context.read<WorkerProvider>().setWorker(worker);
    await context.read<RoleProvider>().setRole(AppRole.worker);
    if (!mounted) return;
    Navigator.push(
      context,
      CupertinoPageRoute<void>(
          builder: (_) => RiskRevealScreen(worker: worker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.tealGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Up Your Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'A few details to personalise your coverage',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: AvatarWidget(
                      name: _name,
                      editable: true,
                      size: 88,
                      imagePath: _imagePath,
                      onChanged: (v) => setState(() => _imagePath = v),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('YOUR FULL NAME'),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) => setState(() => _name = v),
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: const TextStyle(
                                color: AppColors.textSoft, fontSize: 14),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('DELIVERY PLATFORM'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DeliveryPlatform.values.map((platform) {
                            final selected = _platform == platform;
                            final color = Worker(
                              id: 'x',
                              name: 'x',
                              phone: 'x',
                              platform: platform,
                              zone: 'x',
                              city: 'x',
                              tier: RiskTier.medium,
                              weeklyAvgEarnings: 0,
                              trustScore: 0,
                              joinedAt: DateTime.now(),
                            ).platformColor;
                            final name = platform.name[0].toUpperCase() +
                                platform.name.substring(1);
                            return GestureDetector(
                              onTap: () => setState(() => _platform = platform),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                decoration: selected
                                    ? BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: color, width: 2),
                                      )
                                    : BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.divider),
                                      ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PlatformBadge(platform: platform, size: 24),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.textPrimary
                                            : AppColors.textMid,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (selected) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.check_circle,
                                          color: color, size: 13),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: _Label('WEEKLY EARNINGS')),
                            Text(
                              '₹${_earnings.toInt()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.divider,
                            thumbColor: AppColors.primary,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            min: 3000,
                            max: 8000,
                            divisions: 10,
                            value: _earnings,
                            onChanged: (v) => setState(() => _earnings = v),
                          ),
                        ),
                        const Row(
                          children: [
                            Expanded(
                                child: Text('₹3,000',
                                    style: TextStyle(
                                        color: AppColors.textSoft,
                                        fontSize: 10))),
                            Expanded(
                              child: Text('per week',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textSoft, fontSize: 10)),
                            ),
                            Expanded(
                              child: Text('₹8,000',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: AppColors.textSoft, fontSize: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Used to calculate your income protection payout',
                            style: TextStyle(
                                color: AppColors.textSoft, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'Continue',
                    onPressed: _canContinue ? _continue : null,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: child,
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSoft,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );
}
