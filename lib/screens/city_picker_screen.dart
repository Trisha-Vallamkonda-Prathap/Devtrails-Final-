import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gigshield/providers/worker_provider.dart';
import 'package:gigshield/screens/zone_map_screen.dart';
import 'package:gigshield/theme/app_colors.dart';
import 'package:provider/provider.dart';

class CityPickerScreen extends StatefulWidget {
  final bool isFromOnboarding;
  final String? initialCity;

  const CityPickerScreen({
    super.key,
    this.isFromOnboarding = false,
    this.initialCity,
  });

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  String? _selectedCity;

  static const List<Map<String, dynamic>> _cities = [
    {'name': 'Mumbai', 'emoji': '🌊', 'state': 'Maharashtra'},
    {'name': 'Bengaluru', 'emoji': '🌿', 'state': 'Karnataka'},
    {'name': 'Hyderabad', 'emoji': '🏛️', 'state': 'Telangana'},
    {'name': 'Chennai', 'emoji': '🌅', 'state': 'Tamil Nadu'},
    {'name': 'Delhi', 'emoji': '🕌', 'state': 'Delhi NCR'},
    {'name': 'Pune', 'emoji': '🌄', 'state': 'Maharashtra'},
    {'name': 'Kolkata', 'emoji': '🌉', 'state': 'West Bengal'},
    {'name': 'Ahmedabad', 'emoji': '🏺', 'state': 'Gujarat'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCity != null) {
      return;
    }
    final worker = Provider.of<WorkerProvider>(context, listen: false).worker;
    if (worker != null && worker.city.isNotEmpty) {
      _selectedCity = worker.city;
    }
  }

  Future<void> _openMapForCity(String cityName) async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        builder: (_) => ZoneMapScreen(
          cityName: cityName,
          isFromOnboarding: widget.isFromOnboarding,
        ),
      ),
    );

    if (!mounted) return;
    if (widget.isFromOnboarding && selected != null) {
      Navigator.pop(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isFromOnboarding)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  if (!widget.isFromOnboarding) const SizedBox(height: 16),
                  const Text(
                    'Select your city',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose where you deliver',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Popular Cities',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      widget.isFromOnboarding ? 16 : 96,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isCompact ? 3 : 4,
                      childAspectRatio: isCompact ? 0.64 : 0.66,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _cities.length,
                    itemBuilder: (context, i) {
                      final city = _cities[i];
                      final cityName = city['name'] as String;
                      final isSelected = _selectedCity == cityName;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCity = cityName);
                          _openMapForCity(cityName);
                        },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isCompact ? 56 : 60,
                            height: isCompact ? 56 : 60,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E5D66) : const Color(0xFF1A2F36),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF79DEE7) : const Color(0xFF1A4A54),
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                city['emoji'] as String,
                                style: TextStyle(fontSize: isCompact ? 22 : 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cityName,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFFB9F9FF) : Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            city['state'] as String,
                            style: TextStyle(
                              fontSize: isCompact ? 7 : 8,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
                },
              ),
            ),
            if (!widget.isFromOnboarding)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedCity == null
                          ? null
                          : () => _openMapForCity(_selectedCity!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DB5C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        _selectedCity == null
                            ? 'Select a city first'
                            : 'View ${_selectedCity!} areas on map',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
