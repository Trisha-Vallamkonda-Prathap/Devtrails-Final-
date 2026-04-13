import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config.dart';
import '../../theme/app_colors.dart';
import 'zone_map_screen.dart';

class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key, required this.isOnboarding});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, safeTop + 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOnboarding)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                SizedBox(height: isOnboarding ? 0 : 16),
                const Text(
                  'Select your city',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Choose where you deliver',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'POPULAR CITIES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.68,
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
                          isOnboarding: isOnboarding,
                        ),
                      ),
                    ).then((value) {
                      if (value != null) {
                        Navigator.pop(context, value);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Center(
                          child: Text(city['emoji']!, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        city['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        city['state']!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
