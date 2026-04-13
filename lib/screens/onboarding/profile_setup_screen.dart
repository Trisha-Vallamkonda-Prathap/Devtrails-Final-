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
    if (selectedZone == null || !mounted) {
      return;
    }

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
    if (!mounted) {
      return;
    }
    Navigator.push(
      context,
      CupertinoPageRoute<void>(
        builder: (_) => RiskRevealScreen(worker: worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platforms = DeliveryPlatform.values;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Set Up Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Center(
                child: AvatarWidget(
                  name: _name,
                  editable: true,
                  size: 90,
                  imagePath: _imagePath,
                  onChanged: (value) => setState(() => _imagePath = value),
                ),
              ),
            ),
            _section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR FULL NAME',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    onChanged: (value) => setState(() => _name = value),
                    decoration: InputDecoration(
                      hintText: 'Full name',
                      hintStyle:
                          const TextStyle(color: AppColors.textSoft, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.darkBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              marginTop: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVERY PLATFORM',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: platforms.map((platform) {
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
                      final name = platform.name[0].toUpperCase() + platform.name.substring(1);
                      return GestureDetector(
                        onTap: () => setState(() => _platform = platform),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: selected
                              ? BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color, width: 2),
                                )
                              : BoxDecoration(
                                  color: AppColors.darkBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                child: PlatformBadge(platform: platform, size: 28),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textSoft,
                                  fontWeight:
                                      selected ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, color: color, size: 14),
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
            _section(
              marginTop: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'WEEKLY EARNINGS',
                          style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                        ),
                      ),
                      Text(
                        '₹${_earnings.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.darkBorder,
                      thumbColor: AppColors.primaryLight,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
                        child: Text('₹3,000', style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
                      ),
                      Expanded(
                        child: Text('per week',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
                      ),
                      Expanded(
                        child: Text('₹8,000',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Used to calculate your income protection payout',
                      style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GradientButton(
                label: 'Continue →',
                onPressed: _canContinue ? _continue : null,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section({required Widget child, double marginTop = 0}) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, marginTop, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: child,
    );
  }
}
