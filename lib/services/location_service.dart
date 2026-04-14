import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

/// GigShield Location Service
/// - Real GPS via geolocator (no API key)
/// - Reverse geocoding via Nominatim (free, no key)
/// - Anti-spoof: only flags HIGH-confidence spoofing (mock location flag)
class LocationService {
  static const String _nominatimBase =
      'https://nominatim.openstreetmap.org/reverse';

  // Sensor buffers
  final List<double> _accelMagnitudes = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _listening = false;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: get current position with timeout + fallback
  // ─────────────────────────────────────────────────────────────────────────
  Future<LocationResult> getCurrentLocation() async {
    // 1. Permission
    final perm = await _ensurePermission();
    if (!perm.granted) return LocationResult.error(perm.message);

    _startAccelerometer();

    // 2. Try high accuracy, fall back to medium if timeout
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      // Fallback: last known position
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        position = last;
      } else {
        // Final fallback: reduced accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (_) {
          return LocationResult.error(
              'Could not get location. Check that GPS is turned on.');
        }
      }
    } catch (e) {
      return LocationResult.error('Location error: ${e.toString()}');
    }

    // 3. Anti-spoof — only flag if Android isMockLocation is true
    //    We do NOT flag based on WiFi or accelerometer alone (too many false positives)
    final spoofCheck = _checkSpoof(position);
    if (spoofCheck.flagged) {
      return LocationResult.spoofDetected(spoofCheck.reason);
    }

    // 4. Reverse geocode via Nominatim (free)
    final address =
        await _reverseGeocode(position.latitude, position.longitude);

    return LocationResult.success(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      address: address,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANTI-SPOOF: conservative — only HIGH-confidence flags
  // ─────────────────────────────────────────────────────────────────────────
  _SpoofCheck _checkSpoof(Position position) {
    // PRIMARY signal: Android mock location flag (most reliable)
    // isMockLocation is true when a GPS spoofing app is active
    if (position.isMocked) {
      return _SpoofCheck(
        flagged: true,
        reason: 'Mock location detected. Please disable any GPS spoofing apps.',
      );
    }

    // SECONDARY: Impossibly perfect accuracy (< 1m on a phone = impossible)
    if (position.accuracy < 1.0 && position.accuracy > 0) {
      return _SpoofCheck(
        flagged: true,
        reason:
            'GPS accuracy is implausibly perfect. Please disable mock location.',
      );
    }

    // Very poor accuracy = warn but don't block (poor signal ≠ spoof)
    // We simply pass it through and let the caller decide

    return _SpoofCheck(flagged: false, reason: '');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Trajectory plausibility check (call with 2+ positions)
  // Used only at CLAIM time, not during normal location fetch
  // ─────────────────────────────────────────────────────────────────────────
  bool checkTrajectoryPlausible(List<_PositionStamp> trajectory) {
    if (trajectory.length < 2) return true;
    for (int i = 1; i < trajectory.length; i++) {
      final a = trajectory[i - 1];
      final b = trajectory[i];
      final distM = _haversineMeters(a.lat, a.lng, b.lat, b.lng);
      final secs = b.time.difference(a.time).inSeconds;
      if (secs == 0) continue;
      final kmh = (distM / secs) * 3.6;
      if (kmh > 120) return false; // impossible on a delivery bike
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REVERSE GEOCODE — Nominatim (OpenStreetMap, free, no key)
  // ─────────────────────────────────────────────────────────────────────────
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

      // Nominatim address fields vary; try multiple keys
      final neighbourhood = (addr['suburb'] ??
          addr['neighbourhood'] ??
          addr['quarter'] ??
          addr['residential']) as String?;
      final city = (addr['city'] ??
          addr['town'] ??
          addr['municipality'] ??
          addr['county']) as String?;
      final state = addr['state'] as String?;

      return LocationAddress(
        neighbourhood: neighbourhood,
        city: city,
        state: state,
        formattedAddress: json['display_name'] as String?,
      );
    } catch (_) {
      return null; // network error — non-fatal
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Zone resolution from coordinates
  // Returns the name of the nearest known GigShield zone (within 6km)
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // Permission helper — clear user messages
  // ─────────────────────────────────────────────────────────────────────────
  Future<_PermResult> _ensurePermission() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return _PermResult(
        granted: false,
        message: 'Location is turned off. Please enable GPS in settings.',
      );
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
            'Location permission is permanently denied. Enable it in App Settings.',
      );
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
      if (_accelMagnitudes.length > 30) _accelMagnitudes.removeAt(0);
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

// ─────────────────────────────────────────────────────────────────────────────
// Known zone coordinate lookup table
// Each zone has [lat, lng] of its centroid
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, List<double>> kZoneCoords = {
  // Bengaluru
  'Hebbal': [13.0450, 77.5965],
  'Koramangala': [12.9352, 77.6245],
  'Indiranagar': [12.9784, 77.6408],
  'Whitefield': [12.9698, 77.7499],
  'HSR Layout': [12.9116, 77.6370],
  'Electronic City': [12.8399, 77.6770],
  'Marathahalli': [12.9591, 77.6971],
  'Bannerghatta Road': [12.8987, 77.5972],
  // Mumbai
  'Kurla': [19.0728, 72.8826],
  'Dharavi': [19.0437, 72.8540],
  'Andheri': [19.1136, 72.8697],
  'Malad': [19.1864, 72.8490],
  'Sion': [19.0422, 72.8612],
  'Vikhroli': [19.1024, 72.9240],
  'Bandra': [19.0596, 72.8295],
  'Thane': [19.2183, 72.9781],
  // Hyderabad
  'Secunderabad': [17.4399, 78.4983],
  'Banjara Hills': [17.4156, 78.4347],
  'HITEC City': [17.4435, 78.3772],
  'Kukatpally': [17.4849, 78.3995],
  'Gachibowli': [17.4401, 78.3489],
  'Madhapur': [17.4468, 78.3890],
  // Chennai
  'Tambaram': [12.9249, 80.1000],
  'Anna Nagar': [13.0850, 80.2101],
  'Guindy': [13.0067, 80.2206],
  'Velachery': [12.9815, 80.2210],
  'Porur': [13.0348, 80.1568],
  'T Nagar': [13.0418, 80.2341],
  // Delhi
  'Connaught Place': [28.6315, 77.2167],
  'Saket': [28.5244, 77.2090],
  'Dwarka': [28.5921, 77.0460],
  'Rohini': [28.7041, 77.1025],
  // Pune
  'Koregaon Park': [18.5362, 73.8938],
  'Wakad': [18.5990, 73.7612],
  'Hadapsar': [18.5089, 73.9260],
  'Kothrud': [18.5074, 73.8077],
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
  'Koregaon Park': 'Pune',
  'Wakad': 'Pune',
  'Hadapsar': 'Pune',
  'Kothrud': 'Pune',
};

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────
class LocationResult {
  const LocationResult._({
    required this.status,
    this.lat,
    this.lng,
    this.accuracy,
    this.address,
    this.errorMessage,
  });

  final _LocationStatus status;
  final double? lat;
  final double? lng;
  final double? accuracy;
  final LocationAddress? address;
  final String? errorMessage;

  bool get isSuccess => status == _LocationStatus.success;
  bool get isSpoofDetected => status == _LocationStatus.spoofDetected;
  bool get isError => status == _LocationStatus.error;
  bool get isPoorAccuracy => (accuracy ?? 0) > 100;

  factory LocationResult.success({
    required double lat,
    required double lng,
    required double accuracy,
    required LocationAddress? address,
  }) =>
      LocationResult._(
          status: _LocationStatus.success,
          lat: lat,
          lng: lng,
          accuracy: accuracy,
          address: address);

  factory LocationResult.spoofDetected(String reason) => LocationResult._(
      status: _LocationStatus.spoofDetected, errorMessage: reason);

  factory LocationResult.error(String msg) =>
      LocationResult._(status: _LocationStatus.error, errorMessage: msg);
}

enum _LocationStatus { success, spoofDetected, error }

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

class _SpoofCheck {
  const _SpoofCheck({required this.flagged, required this.reason});
  final bool flagged;
  final String reason;
}

class _PermResult {
  const _PermResult({required this.granted, required this.message});
  final bool granted;
  final String message;
}
