import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/location_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/location_service.dart';
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

class _ZoneMapScreenState extends State<ZoneMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _userLatLng;
  double? _userAccuracy;
  Map<String, dynamic>? _selectedZone;
  bool _locating = false;
  bool _showSpoofWarning = false;
  String? _spoofReason;
  String? _zoneWarning;
  String _searchQuery = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const Map<String, LatLng> _cityCenter = {
    'Mumbai': LatLng(19.0760, 72.8777),
    'Bengaluru': LatLng(12.9716, 77.5946),
    'Hyderabad': LatLng(17.3850, 78.4867),
    'Chennai': LatLng(13.0827, 80.2707),
    'Delhi': LatLng(28.6139, 77.2090),
    'Pune': LatLng(18.5204, 73.8567),
  };

  List<Map<String, dynamic>> get _allZones {
    final fromConfig = kZones
        .where((z) => z['city_key'] == widget.cityName)
        .cast<Map<String, dynamic>>()
        .toList();
    if (fromConfig.isNotEmpty) return fromConfig;
    final center =
        _cityCenter[widget.cityName] ?? const LatLng(19.0760, 72.8777);
    return [
      {
        'zone': 'Central ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'medium',
        'premium': 90.0,
        'coverage': 2240.0,
        'lat': center.latitude,
        'lng': center.longitude
      },
      {
        'zone': 'North ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'high',
        'premium': 120.0,
        'coverage': 2500.0,
        'lat': center.latitude + 0.03,
        'lng': center.longitude
      },
      {
        'zone': 'South ${widget.cityName}',
        'city': widget.cityName,
        'tier': 'low',
        'premium': 60.0,
        'coverage': 2000.0,
        'lat': center.latitude - 0.03,
        'lng': center.longitude
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredZones {
    if (_searchQuery.isEmpty) return _allZones;
    return _allZones
        .where((z) => (z['zone'] as String)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  LatLng get _center =>
      _cityCenter[widget.cityName] ?? const LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapController.dispose();
    _searchCtrl.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    setState(() {
      _locating = true;
      _showSpoofWarning = false;
      _zoneWarning = null;
    });

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isSpoofDetected) {
      setState(() {
        _locating = false;
        _showSpoofWarning = true;
        _spoofReason = result.errorMessage;
      });
      return;
    }

    if (result.isError) {
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage ?? 'Could not get location'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final pos = LatLng(result.lat!, result.lng!);
    setState(() {
      _userLatLng = pos;
      _userAccuracy = result.accuracy;
      _locating = false;
    });

    _mapController.move(pos, 14.5);
    _autoSelectNearest(pos);
  }

  void _autoSelectNearest(LatLng pos) {
    Map<String, dynamic>? nearest;
    double min = double.infinity;
    for (final z in _allZones) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        z['lat'] as double,
        z['lng'] as double,
      );
      if (d < min) {
        min = d;
        nearest = z;
      }
    }
    if (nearest != null) setState(() => _selectedZone = nearest);
  }

  Future<void> _onZoneTap(Map<String, dynamic> zone) async {
    setState(() {
      _selectedZone = zone;
      _zoneWarning = null;
    });

    if (_userLatLng != null) {
      final warning =
          await context.read<LocationProvider>().validateZoneSelection(
                zone['zone'] as String,
                _userLatLng!.latitude,
                _userLatLng!.longitude,
              );
      if (mounted && warning != null) {
        setState(() => _zoneWarning = warning);
      }
    }
  }

  Future<void> _confirmZone(Map<String, dynamic> zone) async {
    if (widget.isOnboarding) {
      Navigator.pop(context, zone);
      return;
    }

    final wp = context.read<WorkerProvider>();
    final worker = wp.worker;
    if (worker == null) return;
    await wp.setWorker(worker.copyWith(
      zone: zone['zone'] as String,
      city: zone['city'] as String,
    ));
    if (!mounted) return;
    Navigator.pop(context, zone);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Zone updated to ${zone['zone']}'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12.5,
              onTap: (_, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gigshield',
                maxZoom: 19,
              ),
              CircleLayer(circles: _buildCircles()),
              MarkerLayer(markers: _buildMarkers()),
              if (_userLatLng != null) ...[
                CircleLayer(circles: [
                  CircleMarker(
                    point: _userLatLng!,
                    radius: _userAccuracy ?? 50,
                    useRadiusInMeter: true,
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderColor: AppColors.info.withValues(alpha: 0.5),
                    borderStrokeWidth: 1,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: _userLatLng!,
                    width: 20,
                    height: 20,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.info,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info
                                  .withValues(alpha: _pulseAnim.value * 0.6),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.circle,
                            color: Colors.white, size: 10),
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
          Positioned(
            top: topPad + 8,
            left: 12,
            right: 12,
            child: _TopBar(
              searchCtrl: _searchCtrl,
              cityName: widget.cityName,
              onSearch: (q) => setState(() => _searchQuery = q),
              onBack: () => Navigator.pop(context),
              searchResults: _searchQuery.isNotEmpty ? _filteredZones : [],
              onResultTap: (zone) {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
                _onZoneTap(zone);
                _mapController.move(
                    LatLng(zone['lat'] as double, zone['lng'] as double), 14.0);
              },
            ),
          ),
          Positioned(
            top: topPad + 70,
            right: 12,
            child: _RiskLegend(),
          ),
          Positioned(
            right: 12,
            bottom: _selectedZone != null ? 240 : 24,
            child: _LocateFab(
              loading: _locating,
              pulseAnim: _pulseAnim,
              onTap: _locateMe,
            ),
          ),
          if (_userLatLng != null && !_locating)
            Positioned(
              right: 12,
              bottom: _selectedZone != null ? 300 : 84,
              child: _AccuracyBadge(accuracy: _userAccuracy ?? 0),
            ),
          if (_showSpoofWarning)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _SpoofBanner(
                reason: _spoofReason ?? '',
                onDismiss: () => setState(() => _showSpoofWarning = false),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _selectedZone != null && !_showSpoofWarning ? 0 : -320,
            child: _selectedZone == null
                ? const SizedBox.shrink()
                : _ZoneCard(
                    zone: _selectedZone!,
                    userLatLng: _userLatLng,
                    warning: _zoneWarning,
                    onSelect: () => _confirmZone(_selectedZone!),
                    onDismiss: () => setState(() => _selectedZone = null),
                  ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _allZones.map<Marker>((zone) {
      final tier = zone['tier'] as String;
      final color = tier == 'high'
          ? AppColors.danger
          : tier == 'medium'
              ? AppColors.warning
              : AppColors.success;
      final isSelected = _selectedZone?['zone'] == zone['zone'];
      return Marker(
        point: LatLng(zone['lat'] as double, zone['lng'] as double),
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        child: GestureDetector(
          onTap: () => _onZoneTap(zone),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : color.withValues(alpha: 0.85),
              border:
                  Border.all(color: Colors.white, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
                  blurRadius: isSelected ? 12 : 4,
                ),
              ],
            ),
            child: Icon(Icons.location_on,
                color: Colors.white, size: isSelected ? 22 : 18),
          ),
        ),
      );
    }).toList();
  }

  List<CircleMarker> _buildCircles() {
    return _allZones.map((zone) {
      final tier = zone['tier'] as String;
      final color = tier == 'high'
          ? AppColors.danger
          : tier == 'medium'
              ? AppColors.warning
              : AppColors.success;
      return CircleMarker(
        point: LatLng(zone['lat'] as double, zone['lng'] as double),
        radius: 1200,
        useRadiusInMeter: true,
        color: color.withValues(alpha: 0.07),
        borderColor: color.withValues(alpha: 0.25),
        borderStrokeWidth: 1,
      );
    }).toList();
  }

  void _onMapTap(LatLng point) {
    Map<String, dynamic>? nearest;
    double min = double.infinity;
    for (final z in _allZones) {
      final d = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        z['lat'] as double,
        z['lng'] as double,
      );
      if (d < min && d < 3000) {
        min = d;
        nearest = z;
      }
    }
    if (nearest != null) _onZoneTap(nearest);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.searchCtrl,
    required this.cityName,
    required this.onSearch,
    required this.onBack,
    required this.searchResults,
    required this.onResultTap,
  });

  final TextEditingController searchCtrl;
  final String cityName;
  final ValueChanged<String> onSearch;
  final VoidCallback onBack;
  final List<Map<String, dynamic>> searchResults;
  final ValueChanged<Map<String, dynamic>> onResultTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: kCardShadow,
                ),
                child: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: kCardShadow,
                ),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search zones in $cityName',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textSoft),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSoft, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.textSoft),
                            onPressed: () {
                              searchCtrl.clear();
                              onSearch('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4, left: 54),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kCardShadow,
            ),
            child: Column(
              children: searchResults.take(5).map((z) {
                final tier = z['tier'] as String;
                final color = AppColors.tierColor(tier);
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  title: Text(z['zone'] as String,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${tier.toUpperCase()} · ₹${(z['premium'] as double).toInt()}/wk',
                      style: const TextStyle(fontSize: 10)),
                  onTap: () => onResultTap(z),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _RiskLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LRow(color: AppColors.danger, label: 'High risk'),
          SizedBox(height: 4),
          _LRow(color: AppColors.warning, label: 'Medium risk'),
          SizedBox(height: 4),
          _LRow(color: AppColors.success, label: 'Low risk'),
        ],
      ),
    );
  }
}

class _LRow extends StatelessWidget {
  const _LRow({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _LocateFab extends StatelessWidget {
  const _LocateFab({
    required this.loading,
    required this.pulseAnim,
    required this.onTap,
  });

  final bool loading;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: loading ? pulseAnim.value * 0.5 : 0.2),
                blurRadius: loading ? 18 : 8,
                spreadRadius: loading ? 3 : 0,
              ),
            ],
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.my_location,
                  color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class _AccuracyBadge extends StatelessWidget {
  const _AccuracyBadge({required this.accuracy});
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final color = accuracy < 30
        ? AppColors.success
        : accuracy < 80
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: kCardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed, size: 10, color: color),
          const SizedBox(width: 4),
          Text('±${accuracy.toInt()}m',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SpoofBanner extends StatelessWidget {
  const _SpoofBanner({required this.reason, required this.onDismiss});
  final String reason;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_bad, color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location Verification Failed',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(reason,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        height: 1.4)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 16),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.userLatLng,
    required this.warning,
    required this.onSelect,
    required this.onDismiss,
  });
  final Map<String, dynamic> zone;
  final LatLng? userLatLng;
  final String? warning;
  final VoidCallback onSelect;
  final VoidCallback onDismiss;

  String? _distLabel() {
    if (userLatLng == null) return null;
    final d = Geolocator.distanceBetween(
      userLatLng!.latitude,
      userLatLng!.longitude,
      zone['lat'] as double,
      zone['lng'] as double,
    );
    return d < 1000
        ? '${d.toInt()}m away'
        : '${(d / 1000).toStringAsFixed(1)}km away';
  }

  @override
  Widget build(BuildContext context) {
    final tier = zone['tier'] as String;
    final tierColor = AppColors.tierColor(tier);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(zone['zone'] as String,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          if (_distLabel() != null)
                            Row(children: [
                              const Icon(Icons.near_me,
                                  size: 11, color: AppColors.textSoft),
                              const SizedBox(width: 3),
                              Text(_distLabel()!,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSoft)),
                            ]),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        border: Border.all(
                            color: tierColor.withValues(alpha: 0.45)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('${tier.toUpperCase()} RISK',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tierColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _InfoCol(
                            'Weekly Premium',
                            '₹${(zone['premium'] as double).toInt()}',
                            AppColors.primary)),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(
                        child: _InfoCol(
                            'Coverage',
                            '₹${(zone['coverage'] as double).toInt()}',
                            AppColors.success)),
                  ],
                ),
                if (warning != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(warning!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
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
                    child: const Text('Select this zone',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  const _InfoCol(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSoft)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      );
}
