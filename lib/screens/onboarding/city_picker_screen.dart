import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'zone_map_screen.dart';

class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key, required this.isOnboarding});
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Teal gradient header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, safeTop + 16, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.tealGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOnboarding)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                SizedBox(height: isOnboarding ? 0 : 14),
                const Text(
                  'Select your city',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where you deliver most',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'POPULAR CITIES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── City grid ──
          Expanded(
            child: GridView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
              ),
              itemCount: kCities.length,
              itemBuilder: (_, i) {
                final city = kCities[i];
                return _CityTile(
                  city: city,
                  onTap: () {
                    Navigator.push<Map<String, dynamic>>(
                      context,
                      CupertinoPageRoute<Map<String, dynamic>>(
                        builder: (_) => ZoneMapScreen(
                          cityName: city['name']!,
                          isOnboarding: isOnboarding,
                        ),
                      ),
                    ).then((value) {
                      if (value != null) Navigator.pop(context, value);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.city, required this.onTap});
  final Map<String, String> city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kCardShadow,
            ),
            child: Center(
              child: Text(city['emoji']!,
                  style: const TextStyle(fontSize: 26)),
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
  }
}