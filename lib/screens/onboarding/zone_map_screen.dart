import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/worker_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ZoneMapScreen extends StatefulWidget {
  const ZoneMapScreen({
    super.key,
    required this.cityName,
    required this.isOnboarding,
  });

  final String cityName;
  final bool isOnboarding;

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    if (_zones.isNotEmpty) {
      _selectedIndex = 0;
    }
  }

  static const Map<String, LatLng> _centerMap = {
    'Mumbai': LatLng(19.0760, 72.8777),
    'Bengaluru': LatLng(12.9716, 77.5946),
    'Hyderabad': LatLng(17.3850, 78.4867),
    'Chennai': LatLng(13.0827, 80.2707),
    'Delhi': LatLng(28.6139, 77.2090),
    'Pune': LatLng(18.5204, 73.8567),
    'Kolkata': LatLng(22.5726, 88.3639),
    'Ahmedabad': LatLng(23.0225, 72.5714),
  };

  List<Map<String, dynamic>> get _rawZones => kZones
      .where((z) => z['city_key'] == widget.cityName)
      .cast<Map<String, dynamic>>()
      .toList();

  List<Map<String, dynamic>> get _zones {
    if (_rawZones.isNotEmpty) return _rawZones;
    final center = _centerMap[widget.cityName] ?? const LatLng(19.0760, 72.8777);
    return [
      {
        'zone': 'Central ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'medium',
        'premium': 90.0,
        'coverage': 2240.0,
        'lat': center.latitude,
        'lng': center.longitude,
      },
      {
        'zone': 'North ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'high',
        'premium': 120.0,
        'coverage': 2500.0,
        'lat': center.latitude + 0.03,
        'lng': center.longitude + 0.03,
      },
      {
        'zone': 'South ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'low',
        'premium': 60.0,
        'coverage': 2000.0,
        'lat': center.latitude - 0.03,
        'lng': center.longitude - 0.03,
      },
    ];
  }

  List<Marker> _buildMarkers() {
    return _zones.asMap().entries.map((entry) {
      final i = entry.key;
      final zone = entry.value;
      final tier = zone['tier'] as String;
      final color = tier == 'high'
          ? AppColors.danger
          : tier == 'medium'
              ? AppColors.warning
              : AppColors.success;
      final isSelected = _selectedIndex == i;

      return Marker(
        point: LatLng(zone['lat'] as double, zone['lng'] as double),
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        child: GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : color.withValues(alpha: 0.9),
              border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: isSelected ? 12 : 6,
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: isSelected ? 22 : 18,
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _select(Map<String, dynamic> zone) async {
    if (widget.isOnboarding) {
      Navigator.pop(context, zone);
      return;
    }

    final workerProvider = context.read<WorkerProvider>();
    final worker = workerProvider.worker;
    if (worker == null) return;

    await workerProvider.setWorker(worker.copyWith(
      zone: zone['zone'] as String,
      city: zone['city'] as String,
    ));

    if (!mounted) return;

    Navigator.pop(context, zone);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zone updated to ${zone['zone']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _centerMap[widget.cityName] ?? const LatLng(19.0760, 72.8777);
    final selected = _selectedIndex == null ? null : _zones[_selectedIndex!];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.5,
              onTap: (_, __) => setState(() => _selectedIndex = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gigshield',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _rawZones.isEmpty
                              ? 'No mapped zones yet. Pick a quick area below.'
                              : 'Tap a zone pin to select',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 88,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendRow(color: AppColors.warning, label: 'High risk'),
                  _LegendRow(color: AppColors.info, label: 'Medium risk'),
                  _LegendRow(color: AppColors.success, label: 'Low risk'),
                ],
              ),
            ),
          ),
          if (_zones.isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: selected != null ? 220 : 14,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: kCardShadow,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _zones.asMap().entries.map((entry) {
                    final i = entry.key;
                    final zone = entry.value;
                    return ChoiceChip(
                      label: Text(zone['zone'] as String),
                      selected: _selectedIndex == i,
                      onSelected: (_) => setState(() => _selectedIndex = i),
                    );
                  }).toList(),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: selected != null ? 0 : -280,
            child: selected == null
                ? const SizedBox.shrink()
                : _ZoneCard(
                    zone: selected,
                    onSelect: () => _select(selected),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone, required this.onSelect});

  final Map<String, dynamic> zone;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tier = zone['tier'] as String;
    final tierColor = AppColors.tierColor(tier);

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${zone['zone']} ${zone['city']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.1),
                  border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${tier.toUpperCase()} RISK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoCol(
                  'Weekly Premium',
                  '?${(zone['premium'] as double).toInt()}',
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.divider),
              Expanded(
                child: _infoCol(
                  'Coverage Limit',
                  '?${(zone['coverage'] as double).toInt()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Select this zone ?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
