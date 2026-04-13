import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gigshield/config.dart';
import 'package:gigshield/providers/worker_provider.dart';
import 'package:gigshield/services/risk_engine.dart';
import 'package:gigshield/theme/app_colors.dart';
import 'package:provider/provider.dart';

class ZoneMapScreen extends StatefulWidget {
  final String cityName;
  final bool isFromOnboarding;

  const ZoneMapScreen({
    super.key,
    required this.cityName,
    this.isFromOnboarding = false,
  });

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  GoogleMapController? _mapController;
  int? _selectedZoneIndex;
  bool _showListView = false;

  String get _resolvedCityKey {
    if (_cityZones.containsKey(widget.cityName)) {
      return widget.cityName;
    }
    final normalized = widget.cityName.trim().toLowerCase();
    for (final key in _cityZones.keys) {
      if (key.toLowerCase() == normalized) {
        return key;
      }
    }
    return 'Bengaluru';
  }

  static const Map<String, LatLng> _cityCentres = {
    'Mumbai': LatLng(19.0760, 72.8777),
    'Bengaluru': LatLng(12.9716, 77.5946),
    'Hyderabad': LatLng(17.3850, 78.4867),
    'Chennai': LatLng(13.0827, 80.2707),
    'Delhi': LatLng(28.6139, 77.2090),
    'Pune': LatLng(18.5204, 73.8567),
    'Kolkata': LatLng(22.5726, 88.3639),
    'Ahmedabad': LatLng(23.0225, 72.5714),
  };

  static const Map<String, List<Map<String, dynamic>>> _cityZones = {
    'Mumbai': [
      {'zone': 'Kurla', 'city': 'Mumbai', 'tier': 'high', 'premium': 115.0, 'coverage': 2460.0, 'lat': 19.0728, 'lng': 72.8826},
      {'zone': 'Dharavi', 'city': 'Mumbai', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 19.0437, 'lng': 72.8540},
      {'zone': 'Bandra', 'city': 'Mumbai', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 19.0544, 'lng': 72.8402},
      {'zone': 'Andheri', 'city': 'Mumbai', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 19.1136, 'lng': 72.8697},
      {'zone': 'Dadar', 'city': 'Mumbai', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 19.0178, 'lng': 72.8478},
    ],
    'Bengaluru': [
      {'zone': 'Hebbal', 'city': 'Bengaluru', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 13.0450, 'lng': 77.5965},
      {'zone': 'Koramangala', 'city': 'Bengaluru', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 12.9352, 'lng': 77.6245},
      {'zone': 'Indiranagar', 'city': 'Bengaluru', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 12.9784, 'lng': 77.6408},
      {'zone': 'Whitefield', 'city': 'Bengaluru', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 12.9698, 'lng': 77.7499},
      {'zone': 'HSR Layout', 'city': 'Bengaluru', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 12.9116, 'lng': 77.6370},
    ],
    'Hyderabad': [
      {'zone': 'Secunderabad', 'city': 'Hyderabad', 'tier': 'medium', 'premium': 85.0, 'coverage': 2240.0, 'lat': 17.4399, 'lng': 78.4983},
      {'zone': 'Banjara Hills', 'city': 'Hyderabad', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 17.4156, 'lng': 78.4347},
      {'zone': 'HITEC City', 'city': 'Hyderabad', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 17.4435, 'lng': 78.3772},
      {'zone': 'Kukatpally', 'city': 'Hyderabad', 'tier': 'medium', 'premium': 85.0, 'coverage': 2240.0, 'lat': 17.4849, 'lng': 78.3995},
    ],
    'Chennai': [
      {'zone': 'Tambaram', 'city': 'Chennai', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 12.9249, 'lng': 80.1000},
      {'zone': 'Guindy', 'city': 'Chennai', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 13.0067, 'lng': 80.2206},
      {'zone': 'Anna Nagar', 'city': 'Chennai', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 13.0850, 'lng': 80.2101},
      {'zone': 'Velachery', 'city': 'Chennai', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 12.9815, 'lng': 80.2180},
    ],
    'Delhi': [
      {'zone': 'Dwarka', 'city': 'Delhi', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 28.5921, 'lng': 77.0460},
      {'zone': 'Rohini', 'city': 'Delhi', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 28.7383, 'lng': 77.0822},
      {'zone': 'Karol Bagh', 'city': 'Delhi', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 28.6518, 'lng': 77.1909},
      {'zone': 'Saket', 'city': 'Delhi', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 28.5245, 'lng': 77.2066},
    ],
    'Pune': [
      {'zone': 'Kothrud', 'city': 'Pune', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 18.5074, 'lng': 73.8077},
      {'zone': 'Hinjawadi', 'city': 'Pune', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 18.5912, 'lng': 73.7389},
      {'zone': 'Shivajinagar', 'city': 'Pune', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 18.5308, 'lng': 73.8474},
      {'zone': 'Hadapsar', 'city': 'Pune', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 18.5089, 'lng': 73.9260},
    ],
    'Kolkata': [
      {'zone': 'Salt Lake', 'city': 'Kolkata', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 22.5867, 'lng': 88.4173},
      {'zone': 'Park Street', 'city': 'Kolkata', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 22.5535, 'lng': 88.3521},
      {'zone': 'Howrah', 'city': 'Kolkata', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 22.5958, 'lng': 88.2636},
      {'zone': 'Garia', 'city': 'Kolkata', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 22.4594, 'lng': 88.3913},
    ],
    'Ahmedabad': [
      {'zone': 'Navrangpura', 'city': 'Ahmedabad', 'tier': 'low', 'premium': 60.0, 'coverage': 2000.0, 'lat': 23.0375, 'lng': 72.5601},
      {'zone': 'Maninagar', 'city': 'Ahmedabad', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 22.9951, 'lng': 72.6040},
      {'zone': 'Bopal', 'city': 'Ahmedabad', 'tier': 'medium', 'premium': 90.0, 'coverage': 2240.0, 'lat': 23.0326, 'lng': 72.4636},
      {'zone': 'Naroda', 'city': 'Ahmedabad', 'tier': 'high', 'premium': 120.0, 'coverage': 2500.0, 'lat': 23.0701, 'lng': 72.6738},
    ],
  };

  List<Map<String, dynamic>> get _zones => _cityZones[_resolvedCityKey] ?? const [];

  LatLng get _centre =>
      _cityCentres[_resolvedCityKey] ?? const LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    if (_zones.isEmpty) {
      return;
    }

    _selectedZoneIndex = 0;

    if (widget.isFromOnboarding) {
      return;
    }

    final worker = Provider.of<WorkerProvider>(context, listen: false).worker;
    if (worker == null || worker.city.toLowerCase() != _resolvedCityKey.toLowerCase()) {
      return;
    }
    final index = _zones.indexWhere((z) => z['zone'] == worker.zone);
    if (index >= 0) {
      _selectedZoneIndex = index;
    }
  }

  Set<Marker> get _markers {
    return _zones.asMap().entries.map((entry) {
      final i = entry.key;
      final z = entry.value;
      final tier = (kCityTiers[z['city'] as String] ?? z['tier']) as String;

      final hue = tier == 'high'
          ? BitmapDescriptor.hueOrange
          : tier == 'medium'
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueGreen;

      return Marker(
        markerId: MarkerId('zone_$i'),
        position: LatLng(z['lat'] as double, z['lng'] as double),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: z['zone'] as String,
          snippet: '${tier.toUpperCase()} RISK · ₹${(z['premium'] as double).toInt()}/week',
        ),
        onTap: () => setState(() => _selectedZoneIndex = i),
      );
    }).toSet();
  }

  void _focusZone(int index) {
    if (index < 0 || index >= _zones.length) {
      return;
    }
    final zone = _zones[index];
    setState(() => _selectedZoneIndex = index);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(zone['lat'] as double, zone['lng'] as double),
          zoom: 13.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_zones.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.cityName,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'No zones available for ${widget.cityName}',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final selectedZone =
        _selectedZoneIndex != null ? _zones[_selectedZoneIndex!] : null;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          Visibility(
            visible: !_showListView,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _centre,
                zoom: 12.5,
              ),
              markers: _markers,
              onMapCreated: (c) => _mapController = c,
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Visibility(
            visible: _showListView,
            child: _buildListView(),
          ),
          if (_zones.isEmpty)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                alignment: Alignment.center,
                child: const Text(
                  'No zones configured for this city yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1F24), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cityName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Tap a zone to select',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(AppColors.warning, 'High risk'),
                  const SizedBox(height: 4),
                  _legendItem(AppColors.info, 'Medium risk'),
                  const SizedBox(height: 4),
                  _legendItem(AppColors.success, 'Low risk'),
                ],
              ),
            ),
          ),
          if (_zones.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: selectedZone != null ? 210 : 8,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: _zones.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final zone = _zones[index];
                      final cityTier = (kCityTiers[zone['city'] as String] ?? zone['tier']) as String;
                      final tierColor = AppColors.tierColor(cityTier);
                      final isSelected = _selectedZoneIndex == index;
                      return ChoiceChip(
                        label: Text(zone['zone'] as String),
                        selected: isSelected,
                        onSelected: (_) => _focusZone(index),
                        selectedColor: tierColor.withValues(alpha: 0.22),
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        side: BorderSide(
                          color: isSelected ? tierColor : Colors.white24,
                        ),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: selectedZone != null ? 0 : -220,
            left: 0,
            right: 0,
            child: _buildZoneCard(selectedZone),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showListView = !_showListView;
          });
        },
        child: Icon(_showListView ? Icons.map : Icons.list),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        final tier = (kCityTiers[zone['city'] as String] ?? zone['tier']) as String;
        final tierColor = AppColors.tierColor(tier);
        return ListTile(
          title: Text(zone['zone'] as String),
          subtitle: Text(
              '${tier.toUpperCase()} RISK · ₹${(zone['premium'] as double).toInt()}/week'),
          tileColor: _selectedZoneIndex == index ? tierColor.withOpacity(0.2) : null,
          onTap: () {
            setState(() {
              _selectedZoneIndex = index;
              _showListView = false;
            });
            _focusZone(index);
          },
        );
      },
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ],
    );
  }

  Widget _buildZoneCard(Map<String, dynamic>? zone) {
    if (zone == null) return const SizedBox.shrink();
    final cityTier = (kCityTiers[zone['city'] as String] ?? zone['tier']) as String;
    final tier = cityTier;
    final tierColor = AppColors.tierColor(tier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${zone['zone']}, ${zone['city']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tierColor.withValues(alpha: 0.4)),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoCell(
                  'Weekly Premium',
                  '₹${(zone['premium'] as double).toInt()}',
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _infoCell(
                  'Coverage Limit',
                  '₹${(zone['coverage'] as double).toInt()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryMid, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _selectZone(zone),
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Text(
                      'Select this zone →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _selectZone(Map<String, dynamic> zone) {
    final cityName = zone['city'] as String;
    final tier = RiskEngine.getTier(
      zone['zone'] as String,
      city: cityName,
    );
    final premium = RiskEngine.getPremium(tier, city: cityName);
    final coverage = RiskEngine.getCoverageLimit(tier, city: cityName);

    if (widget.isFromOnboarding) {
      Navigator.pop(
        context,
        {
          ...zone,
          'tier': tier.name,
          'premium': premium,
          'coverage': coverage,
        },
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final current = workerProvider.worker;
    if (current != null) {
      workerProvider.setWorker(
        current.copyWith(
          zone: zone['zone'] as String,
          city: cityName,
          tier: tier,
        ),
      );
    }

    Navigator.pop(context);
    Navigator.pop(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Zone updated to ${zone['zone']}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
