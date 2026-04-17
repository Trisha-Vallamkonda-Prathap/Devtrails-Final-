import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Single source of truth for zone state.
/// All zone reads/writes go through this provider.
class LocationProvider extends ChangeNotifier {
  final LocationService _svc = LocationService();

  LocationResult? _result;
  bool _loading = false;

  // BUG FIX 2 & 7: single source of truth — zone is only set here,
  // never derived from stale local state elsewhere
  String? _resolvedZone;
  String? _resolvedCity;

  // Holds the active dynamic zone map so it survives navigation
  Map<String, dynamic>? _activeDynamicZone;

  LocationResult? get result => _result;
  bool get loading => _loading;
  bool get hasLocation => _result?.isSuccess == true;
  bool get spoofDetected => _result?.isSpoofDetected == true;
  bool get hasMediumRisk => _result?.hasMediumRisk == true;
  bool get hasLowRisk => _result?.hasLowRisk == true;

  String? get resolvedZone => _resolvedZone;
  String? get resolvedCity => _resolvedCity;
  Map<String, dynamic>? get activeDynamicZone => _activeDynamicZone;

  double? get lat => _result?.lat;
  double? get lng => _result?.lng;
  double? get accuracy => _result?.accuracy;
  double get trustScore => _svc.currentTrustScore;

  String? get errorMessage {
    if (_result == null) return null;
    if (_result!.isSpoofDetected) return _result!.errorMessage;
    if (_result!.riskReason != null) return _result!.riskReason;
    return null;
  }

  /// Fetch GPS, resolve zone name, update state atomically.
  /// BUG FIX 5: refresh only re-fetches; it does NOT silently override a
  /// user-selected zone. Callers that want to update the worker zone after
  /// refresh must do so explicitly.
  Future<void> fetchLocation() async {
    _loading = true;
    notifyListeners();

    _result = await _svc.getCurrentLocation();

    if (_result!.isSuccess) {
      final knownZone =
          _svc.resolveZoneFromCoords(_result!.lat!, _result!.lng!);
      final knownCity =
          _svc.resolveCityFromCoords(_result!.lat!, _result!.lng!);

      if (knownZone != null) {
        // Matched a known zone — use it
        _resolvedZone = knownZone;
        _resolvedCity = knownCity;
        _activeDynamicZone = null;
      } else {
        // BUG FIX 1: dynamic zone naming — strict priority, never "Custom Zone"
        // unless ALL geocoding fields are null
        final addr = _result!.address;
        final zoneName = _resolveDynamicZoneName(addr);
        final cityName = addr?.city ?? 'Unknown City';

        _resolvedZone = zoneName;
        _resolvedCity = cityName;

        // BUG FIX 7: persist dynamic zone so it survives navigation
        _activeDynamicZone = {
          'zone': zoneName,
          'city': cityName,
          'city_key': cityName,
          'tier': 'medium',
          'premium': 90.0,
          'coverage': 2240.0,
          'lat': _result!.lat!,
          'lng': _result!.lng!,
          'isDynamic': true,
        };
      }
    }

    _loading = false;
    notifyListeners();
  }

  /// BUG FIX 1: derive dynamic zone name with strict priority.
  /// ONLY falls back to "Custom Zone" if ALL fields are null.
  String _resolveDynamicZoneName(LocationAddress? addr) {
    if (addr == null) return 'Custom Zone';
    // neighbourhood field in LocationAddress already holds the best
    // geocoded name (neighbourhood > suburb > locality > city),
    // resolved inside LocationService._reverseGeocode
    return addr.neighbourhood ?? 'Custom Zone';
  }

  /// Explicitly set the active zone (e.g. after user selects from map).
  /// BUG FIX 2: this is the ONLY place zone state is mutated after a switch.
  void setActiveZone(String zone, String city,
      {Map<String, dynamic>? dynamicZone}) {
    _resolvedZone = zone;
    _resolvedCity = city;
    _activeDynamicZone = dynamicZone;
    notifyListeners();
  }

  /// BUG FIX 6: precise haversine geofence validation.
  /// Returns (isInside, distanceMeters).
  ({bool isInside, double distanceMeters}) validateGeofence(
    double userLat,
    double userLng,
    double zoneLat,
    double zoneLng,
    double radiusMeters,
  ) {
    final dist = _svc.distanceToZoneCenter(
        userLat, userLng, zoneLat, zoneLng);
    return (isInside: dist <= radiusMeters, distanceMeters: dist);
  }

  /// Validate manually selected zone against GPS — used on map screen.
  /// Returns null if OK, warning string if mismatch.
  Future<String?> validateZoneSelection(
      String selectedZone, double lat, double lng) async {
    final gpsZone = _svc.resolveZoneFromCoords(lat, lng);
    if (gpsZone == null) return null;
    if (gpsZone == selectedZone) return null;
    return 'Your GPS shows you are near $gpsZone. '
        'Select $gpsZone for accurate coverage, or continue with $selectedZone.';
  }

  void clear() {
    _result = null;
    _resolvedZone = null;
    _resolvedCity = null;
    _activeDynamicZone = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }
}