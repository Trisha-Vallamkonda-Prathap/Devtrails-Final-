import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

/// GigShield Location Service
/// Multi-layer anti-spoofing: 6 defence layers, never blocks user.
class LocationService {
  static const String _nominatimBase =
      'https://nominatim.openstreetmap.org/reverse';

  // ── Sensor buffers ──
  final List<double> _accelMagnitudes = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _listening = false;

  // ── Trajectory (last 5 positions) ──
  final List<_PositionStamp> _trajectory = [];

  // ── Layer 4: fraud ring detection ──
  final List<DateTime> _locationFetchTimes = [];
  int _rapidSwitchCount = 0;

  // ── Layer 6: adaptive trust score (0–100, higher = more trusted) ──
  double _trustScore = 70.0;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: get current position with timeout + fallback
  // ─────────────────────────────────────────────────────────────────────────
  Future<LocationResult> getCurrentLocation() async {
    final perm = await _ensurePermission();
    if (!perm.granted) return LocationResult.error(perm.message);

    _startAccelerometer();
    _recordFetchTime();

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp).inSeconds.abs() < 10) {
        position = last;
      } else {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (_) {
          return LocationResult.error(
              'Could not get location. Please ensure GPS is enabled.');
        }
      }
    } catch (e) {
      return LocationResult.error('Location error: ${e.toString()}');
    }

    // ── Record trajectory ──
    _trajectory.add(_PositionStamp(
      lat: position.latitude,
      lng: position.longitude,
      time: DateTime.now(),
    ));
    if (_trajectory.length > 5) _trajectory.removeAt(0);

    // ── Run multi-layer risk analysis ──
    final riskResult = await _runMultiLayerAnalysis(position);

    // HIGH risk (mock location) — this is the only soft-block
    if (riskResult.level == _RiskLevel.high) {
      _adjustTrust(-15);
      return LocationResult.spoofDetected(riskResult.reason);
    }

    // MEDIUM/LOW: pass through with risk metadata — never block
    if (riskResult.level == _RiskLevel.medium ||
        riskResult.level == _RiskLevel.low) {
      _adjustTrust(-5);
    } else {
      _adjustTrust(3);
    }

    final address =
        await _reverseGeocode(position.latitude, position.longitude);

    return LocationResult.success(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      address: address,
      riskScore: riskResult.score,
      riskReason:
          riskResult.level != _RiskLevel.normal ? riskResult.reason : null,
      trustScore: _trustScore,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MULTI-LAYER RISK ANALYSIS
  // ─────────────────────────────────────────────────────────────────────────
  Future<_RiskResult> _runMultiLayerAnalysis(Position position) async {
    int score = 0;
    final reasons = <String>[];

    // ── LAYER 1: Core signal — isMocked (highest confidence) ──────────────
    if (position.isMocked) {
      return _RiskResult(
        level: _RiskLevel.high,
        score: 100,
        reason: 'Mock location detected. Please disable any GPS spoofing apps.',
      );
    }

    // Implausibly perfect accuracy — another high-confidence spoof signal
    if (position.accuracy > 0 && position.accuracy < 1.0) {
      return _RiskResult(
        level: _RiskLevel.high,
        score: 100,
        reason:
            'GPS accuracy is implausibly perfect. Please disable mock location.',
      );
    }

    // ── LAYER 1b: Sensor fusion — accelerometer vs GPS ─────────────────────
    final accelVar = _accelVariance();
    final isStationary = accelVar < 0.02;
    if (isStationary && position.accuracy < 10) {
      score += 22;
      reasons.add('device appears static but GPS shows high accuracy');
    }

    // ── LAYER 1c: Network context ──────────────────────────────────────────
    final connectivity = await Connectivity().checkConnectivity();
    final isOnWifi = connectivity == ConnectivityResult.wifi;
    if (isOnWifi && isStationary && position.accuracy < 15) {
      score += 10;
      reasons.add('stable WiFi with no movement and high GPS accuracy');
    }

    // ── LAYER 2: Platform activity coherence ───────────────────────────────
    if (_trajectory.length >= 3) {
      final allSame = _trajectory.every((p) =>
          (p.lat - _trajectory.first.lat).abs() < 0.0001 &&
          (p.lng - _trajectory.first.lng).abs() < 0.0001);
      if (allSame) {
        score += 15;
        reasons.add('location has been perfectly static across multiple reads');
      }
    }

    // ── LAYER 3: Geospatial trajectory — teleport / unrealistic speed ──────
    if (_trajectory.length >= 2) {
      if (!_checkTrajectoryPlausible(_trajectory)) {
        score += 40;
        reasons.add('sudden location jump detected');
      }
    }

    // ── LAYER 4: Fraud ring detection — rapid repeated fetches ────────────
    if (_rapidSwitchCount >= 5) {
      score += 20;
      reasons.add('unusually frequent location requests detected');
    }

    // ── LAYER 5: Mobility context — poor accuracy is NOT spoof ────────────
    if (position.accuracy > 100) {
      score += 5;
    }

    // Stale timestamp > 30s — just refresh signal, not spoof
    final age = DateTime.now().difference(position.timestamp).inSeconds.abs();
    if (age > 30) {
      score += 3;
    }

    // ── LAYER 6: Adaptive trust score modifier ─────────────────────────────
    if (_trustScore < 40) {
      score += 10;
    }

    // ── Classify final risk level ──────────────────────────────────────────
    if (score >= 50) {
      return _RiskResult(
        level: _RiskLevel.medium,
        score: score,
        reason:
            'We\'ve detected a possible location inconsistency. Your access is not affected.',
      );
    }
    if (score >= 15) {
      return _RiskResult(
        level: _RiskLevel.low,
        score: score,
        reason:
            'Location signal is weak or imprecise. Data may be approximate.',
      );
    }
    return _RiskResult(level: _RiskLevel.normal, score: score, reason: '');
  }

  double _accelVariance() {
    if (_accelMagnitudes.length < 3) return 1.0;
    final mean =
        _accelMagnitudes.reduce((a, b) => a + b) / _accelMagnitudes.length;
    final variance = _accelMagnitudes
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        _accelMagnitudes.length;
    return variance;
  }

  void _recordFetchTime() {
    final now = DateTime.now();
    _locationFetchTimes.add(now);
    _locationFetchTimes.removeWhere((t) => now.difference(t).inSeconds > 60);
    _rapidSwitchCount = _locationFetchTimes.length;
  }

  void _adjustTrust(double delta) {
    _trustScore = (_trustScore + delta).clamp(0.0, 100.0);
  }

  double get currentTrustScore => _trustScore;

  bool _checkTrajectoryPlausible(List<_PositionStamp> trajectory) {
    if (trajectory.length < 2) return true;
    for (int i = 1; i < trajectory.length; i++) {
      final a = trajectory[i - 1];
      final b = trajectory[i];
      final distM = _haversineMeters(a.lat, a.lng, b.lat, b.lng);
      final secs = b.time.difference(a.time).inSeconds.abs();
      if (secs == 0) continue;
      final kmh = (distM / secs) * 3.6;
      if (distM > 5000 && secs < 5) return false;
      if (kmh > 120) return false;
    }
    return true;
  }

  // ── Reverse geocode (Nominatim) ───────────────────────────────────────────
  // Priority: neighbourhood > suburb > locality > city
  Future<LocationAddress?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_nominatimBase?lat=$lat&lon=$lng&format=json&addressdetails=1&zoom=16');
      final res = await http.get(uri, headers: {
        'User-Agent': 'GigShield/2.0 (contact@gigshield.app)',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = json['address'] as Map<String, dynamic>?;
      if (addr == null) return null;

      // BUG FIX 1: strict priority — neighbourhood > suburb > locality > city
      // NEVER fallback to "Custom Zone" here; that is the caller's job
      final neighbourhood = addr['neighbourhood'] as String?;
      final suburb = addr['suburb'] as String?;
      final locality = addr['locality'] as String? ??
          addr['quarter'] as String? ??
          addr['residential'] as String?;
      final city = (addr['city'] ??
          addr['town'] ??
          addr['municipality'] ??
          addr['county']) as String?;
      final state = addr['state'] as String?;

      // Best zone name: neighbourhood > suburb > locality > city
      // null means ALL fields are null — caller decides fallback label
      final bestZoneName = neighbourhood ?? suburb ?? locality ?? city;

      return LocationAddress(
        neighbourhood: bestZoneName,
        city: city,
        state: state,
        formattedAddress: json['display_name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Zone resolution ──────────────────────────────────────────────────────
  String? resolveZoneFromCoords(double lat, double lng) {
    String? nearest;
    double minDist = double.infinity;
    kZoneCoords.forEach((zone, coords) {
      final dist = _haversineMeters(lat, lng, coords[0], coords[1]);
      if (dist < minDist) {
        minDist = dist;
        nearest = zone;
      }
    });
    return minDist < 6000 ? nearest : null;
  }

  String? resolveCityFromCoords(double lat, double lng) {
    final zone = resolveZoneFromCoords(lat, lng);
    if (zone == null) return null;
    return kZoneCity[zone];
  }

  /// Precise geofence check: is (userLat,userLng) within [radiusMeters] of zone centre?
  bool isInsideZone(
    double userLat,
    double userLng,
    double zoneLat,
    double zoneLng,
    double radiusMeters,
  ) {
    return _haversineMeters(userLat, userLng, zoneLat, zoneLng) <=
        radiusMeters;
  }

  double distanceToZoneCenter(
    double userLat,
    double userLng,
    double zoneLat,
    double zoneLng,
  ) =>
      _haversineMeters(userLat, userLng, zoneLat, zoneLng);

  Future<_PermResult> _ensurePermission() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return _PermResult(
          granted: false,
          message: 'Location is turned off. Please enable GPS in settings.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return _PermResult(
          granted: false, message: 'Location permission denied.');
    }
    if (perm == LocationPermission.deniedForever) {
      return _PermResult(
          granted: false,
          message:
              'Location permission is permanently denied. Please enable it in App Settings.');
    }
    return _PermResult(granted: true, message: '');
  }

  void _startAccelerometer() {
    if (_listening) return;
    _listening = true;
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _accelMagnitudes.add(mag);
      if (_accelMagnitudes.length > 40) _accelMagnitudes.removeAt(0);
    });
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double d) => d * math.pi / 180;

  void dispose() {
    _accelSub?.cancel();
    _listening = false;
  }
}

// ── Zone coordinate lookup ────────────────────────────────────────────────────
const Map<String, List<double>> kZoneCoords = {
  // Bengaluru (8 zones)
  'Hebbal': [13.0450, 77.5965],
  'Koramangala': [12.9352, 77.6245],
  'Indiranagar': [12.9784, 77.6408],
  'Whitefield': [12.9698, 77.7499],
  'HSR Layout': [12.9116, 77.6370],
  'Electronic City': [12.8399, 77.6770],
  'Marathahalli': [12.9591, 77.6971],
  'Bannerghatta Road': [12.8987, 77.5972],
  // Mumbai (8 zones)
  'Kurla': [19.0728, 72.8826],
  'Dharavi': [19.0437, 72.8540],
  'Andheri': [19.1136, 72.8697],
  'Malad': [19.1864, 72.8490],
  'Sion': [19.0422, 72.8612],
  'Vikhroli': [19.1024, 72.9240],
  'Bandra': [19.0596, 72.8295],
  'Thane': [19.2183, 72.9781],
  // Hyderabad (6 zones)
  'Secunderabad': [17.4399, 78.4983],
  'Banjara Hills': [17.4156, 78.4347],
  'HITEC City': [17.4435, 78.3772],
  'Kukatpally': [17.4849, 78.3995],
  'Gachibowli': [17.4401, 78.3489],
  'Madhapur': [17.4468, 78.3890],
  // Chennai (6 zones)
  'Tambaram': [12.9249, 80.1000],
  'Anna Nagar': [13.0850, 80.2101],
  'Guindy': [13.0067, 80.2206],
  'Velachery': [12.9815, 80.2210],
  'Porur': [13.0348, 80.1568],
  'T Nagar': [13.0418, 80.2341],
  // Delhi (6 zones)
  'Connaught Place': [28.6315, 77.2167],
  'Saket': [28.5244, 77.2090],
  'Dwarka': [28.5921, 77.0460],
  'Rohini': [28.7041, 77.1025],
  'Laxmi Nagar': [28.6318, 77.2781],
  'Janakpuri': [28.6219, 77.0878],
  // Pune (6 zones)
  'Koregaon Park': [18.5362, 73.8938],
  'Wakad': [18.5990, 73.7612],
  'Hadapsar': [18.5089, 73.9260],
  'Kothrud': [18.5074, 73.8077],
  'Viman Nagar': [18.5679, 73.9143],
  'Hinjewadi': [18.5912, 73.7389],
};

const Map<String, String> kZoneCity = {
  'Hebbal': 'Bengaluru',
  'Koramangala': 'Bengaluru',
  'Indiranagar': 'Bengaluru',
  'Whitefield': 'Bengaluru',
  'HSR Layout': 'Bengaluru',
  'Electronic City': 'Bengaluru',
  'Marathahalli': 'Bengaluru',
  'Bannerghatta Road': 'Bengaluru',
  'Kurla': 'Mumbai',
  'Dharavi': 'Mumbai',
  'Andheri': 'Mumbai',
  'Malad': 'Mumbai',
  'Sion': 'Mumbai',
  'Vikhroli': 'Mumbai',
  'Bandra': 'Mumbai',
  'Thane': 'Mumbai',
  'Secunderabad': 'Hyderabad',
  'Banjara Hills': 'Hyderabad',
  'HITEC City': 'Hyderabad',
  'Kukatpally': 'Hyderabad',
  'Gachibowli': 'Hyderabad',
  'Madhapur': 'Hyderabad',
  'Tambaram': 'Chennai',
  'Anna Nagar': 'Chennai',
  'Guindy': 'Chennai',
  'Velachery': 'Chennai',
  'Porur': 'Chennai',
  'T Nagar': 'Chennai',
  'Connaught Place': 'Delhi',
  'Saket': 'Delhi',
  'Dwarka': 'Delhi',
  'Rohini': 'Delhi',
  'Laxmi Nagar': 'Delhi',
  'Janakpuri': 'Delhi',
  'Koregaon Park': 'Pune',
  'Wakad': 'Pune',
  'Hadapsar': 'Pune',
  'Kothrud': 'Pune',
  'Viman Nagar': 'Pune',
  'Hinjewadi': 'Pune',
};

// ── Data classes ──────────────────────────────────────────────────────────────
class LocationResult {
  const LocationResult._({
    required this.status,
    this.lat,
    this.lng,
    this.accuracy,
    this.address,
    this.errorMessage,
    this.riskScore = 0,
    this.riskReason,
    this.trustScore = 70.0,
  });

  final LocationStatus status;
  final double? lat;
  final double? lng;
  final double? accuracy;
  final LocationAddress? address;
  final String? errorMessage;
  final int riskScore;
  final String? riskReason;
  final double trustScore;

  bool get isSuccess => status == LocationStatus.success;
  bool get isSpoofDetected => status == LocationStatus.spoofDetected;
  bool get isError => status == LocationStatus.error;
  bool get isPoorAccuracy => (accuracy ?? 0) > 100;
  bool get hasMediumRisk => riskScore >= 50;
  bool get hasLowRisk => riskScore >= 15 && riskScore < 50;

  factory LocationResult.success({
    required double lat,
    required double lng,
    required double accuracy,
    required LocationAddress? address,
    int riskScore = 0,
    String? riskReason,
    double trustScore = 70.0,
  }) =>
      LocationResult._(
        status: LocationStatus.success,
        lat: lat,
        lng: lng,
        accuracy: accuracy,
        address: address,
        riskScore: riskScore,
        riskReason: riskReason,
        trustScore: trustScore,
      );

  factory LocationResult.spoofDetected(String reason) => LocationResult._(
        status: LocationStatus.spoofDetected,
        errorMessage: reason,
      );

  factory LocationResult.error(String msg) =>
      LocationResult._(status: LocationStatus.error, errorMessage: msg);
}

enum LocationStatus { success, spoofDetected, error }

enum _RiskLevel { normal, low, medium, high }

class _RiskResult {
  const _RiskResult(
      {required this.level, required this.score, required this.reason});
  final _RiskLevel level;
  final int score;
  final String reason;
}

class LocationAddress {
  const LocationAddress(
      {this.neighbourhood, this.city, this.state, this.formattedAddress});
  final String? neighbourhood;
  final String? city;
  final String? state;
  final String? formattedAddress;
  String get displayZone => neighbourhood ?? city ?? '';
  String get displayCity => city ?? '';
}

class _PositionStamp {
  const _PositionStamp(
      {required this.lat, required this.lng, required this.time});
  final double lat;
  final double lng;
  final DateTime time;
}

class _PermResult {
  const _PermResult({required this.granted, required this.message});
  final bool granted;
  final String message;
}