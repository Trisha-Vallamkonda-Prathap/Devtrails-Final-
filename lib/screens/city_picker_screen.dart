import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/location_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'zone_map_screen.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key, required this.isOnboarding});
  final bool isOnboarding;

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  bool _detecting = false;
  String? _detectError;

  Future<void> _autoDetect() async {
    setState(() {
      _detecting = true;
      _detectError = null;
    });

    final locationProvider = context.read<LocationProvider>();
    await locationProvider.fetchLocation();

    if (!mounted) return;
    setState(() => _detecting = false);

    if (locationProvider.spoofDetected) {
      _showSpoofDialog(locationProvider.errorMessage ?? '');
      return;
    }

    if (!locationProvider.hasLocation) {
      setState(() => _detectError = locationProvider.errorMessage ??
          'Could not detect location. Check GPS settings.');
      return;
    }

    final city = locationProvider.resolvedCity;
    final knownCity = _matchKnownCity(city ?? '');

    if (!mounted) return;
    Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute<Map<String, dynamic>>(
        builder: (_) => ZoneMapScreen(
          cityName: knownCity,
          isOnboarding: widget.isOnboarding,
        ),
      ),
    ).then((zone) {
      if (zone != null && mounted) Navigator.pop(context, zone);
    });
  }

  String _matchKnownCity(String detected) {
    final d = detected.toLowerCase();
    if (d.contains('bengaluru') || d.contains('bangalore')) return 'Bengaluru';
    if (d.contains('mumbai') || d.contains('bombay')) return 'Mumbai';
    if (d.contains('hyderabad')) return 'Hyderabad';
    if (d.contains('chennai') || d.contains('madras')) return 'Chennai';
    if (d.contains('delhi')) return 'Delhi';
    if (d.contains('pune')) return 'Pune';
    return 'Bengaluru';
  }

  void _showSpoofDialog(String reason) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad, color: AppColors.danger),
            SizedBox(width: 10),
            Expanded(
              child: Text('Location Verification Failed',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A mock GPS location was detected on your device.',
                style: TextStyle(fontSize: 13)),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(reason,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 11)),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
                'Please disable any GPS spoofing or mock location apps and try again.',
                style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isOnboarding)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                SizedBox(height: widget.isOnboarding ? 0 : 8),
                const Text(
                  'Where do you deliver?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your city or let us detect it automatically.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _detecting ? null : _autoDetect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        if (_detecting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.my_location,
                              color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detect my location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _detecting
                                    ? 'Checking GPS...'
                                    : 'Auto-select nearest zone',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
                if (_detectError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_detectError!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'SELECT CITY',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.divider)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: kCities.length,
              itemBuilder: (_, i) {
                final city = kCities[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push<Map<String, dynamic>>(
                      context,
                      CupertinoPageRoute<Map<String, dynamic>>(
                        builder: (_) => ZoneMapScreen(
                          cityName: city['name']!,
                          isOnboarding: widget.isOnboarding,
                        ),
                      ),
                    ).then((zone) {
                      if (zone != null && mounted) {
                        Navigator.pop(context, zone);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: kCardShadow,
                        ),
                        child: Center(
                          child: Text(city['emoji']!,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        city['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        city['state']!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
