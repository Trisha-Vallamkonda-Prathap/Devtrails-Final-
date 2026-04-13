import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/insurer/mock_data.dart';
import '../../models/insurer_models.dart';
import '../../theme/insurer_colors.dart';

class ZoneRiskHeatmapScreen extends StatefulWidget {
  const ZoneRiskHeatmapScreen({super.key});

  @override
  State<ZoneRiskHeatmapScreen> createState() => _ZoneRiskHeatmapScreenState();
}

class _ZoneRiskHeatmapScreenState extends State<ZoneRiskHeatmapScreen> {
  CityRiskEntry? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsurerColors.background,
      appBar: AppBar(
        backgroundColor: InsurerColors.background,
        elevation: 0,
        title: const Text(
          'Zone Risk Heatmap',
          style: TextStyle(color: InsurerColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(20.5937, 78.9629),
              initialZoom: 4.2,
              interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gigshield.app',
              ),
              CircleLayer(
                circles: mockCityRisk.map((city) {
                  final color = city.claimDensity >= 85
                      ? Colors.redAccent
                      : city.claimDensity >= 60
                          ? Colors.orangeAccent
                          : Colors.greenAccent;
                  return CircleMarker(
                    point: LatLng(city.latitude, city.longitude),
                    radius: 18000 + (city.claimDensity * 800.0),
                    color: color.withValues(alpha: 0.20),
                    borderColor: color.withValues(alpha: 0.6),
                    borderStrokeWidth: 1.5,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: mockCityRisk.map((city) {
                  final color = city.claimDensity >= 85
                      ? Colors.redAccent
                      : city.claimDensity >= 60
                          ? Colors.orangeAccent
                          : Colors.greenAccent;
                  return Marker(
                    point: LatLng(city.latitude, city.longitude),
                    width: 54,
                    height: 54,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = city),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.25),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: const Icon(Icons.location_city, color: Colors.white, size: 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InsurerColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: InsurerColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selected!.city,
                            style: const TextStyle(
                              color: InsurerColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.close, color: InsurerColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      'Active workers: ${_selected!.activeWorkers}',
                      style: const TextStyle(color: InsurerColors.textSecondary),
                    ),
                    Text(
                      'Claims this month: ${_selected!.claimsThisMonth}',
                      style: const TextStyle(color: InsurerColors.textSecondary),
                    ),
                    Text(
                      'Fraud flags: ${_selected!.fraudFlags}',
                      style: const TextStyle(color: InsurerColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InsurerColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: InsurerColors.border),
              ),
              child: const Row(
                children: [
                  _LegendDot(color: Colors.greenAccent, label: 'Low risk'),
                  SizedBox(width: 12),
                  _LegendDot(color: Colors.orangeAccent, label: 'Moderate'),
                  SizedBox(width: 12),
                  _LegendDot(color: Colors.redAccent, label: 'High risk'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: InsurerColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
