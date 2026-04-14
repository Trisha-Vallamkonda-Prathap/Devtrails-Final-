import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _svc = LocationService();

  LocationResult? _result;
  bool _loading = false;
  String? _resolvedZone;
  String? _resolvedCity;

  LocationResult? get result => _result;
  bool get loading => _loading;
  bool get hasLocation => _result?.isSuccess == true;
  bool get spoofDetected => _result?.isSpoofDetected == true;
  String? get resolvedZone => _resolvedZone;
  String? get resolvedCity => _resolvedCity;
  double? get lat => _result?.lat;
  double? get lng => _result?.lng;
  double? get accuracy => _result?.accuracy;
  String? get errorMessage => _result?.errorMessage;

  Future<void> fetchLocation() async {
    _loading = true;
    notifyListeners();

    _result = await _svc.getCurrentLocation();

    if (_result!.isSuccess) {
      _resolvedZone = _svc.resolveZoneFromCoords(_result!.lat!, _result!.lng!);
      _resolvedCity = _svc.resolveCityFromCoords(_result!.lat!, _result!.lng!);
    }

    _loading = false;
    notifyListeners();
  }

  /// Validate that a manually selected zone matches current GPS position.
  /// Returns null if OK, or a warning message if mismatch.
  Future<String?> validateZoneSelection(
      String selectedZone, double lat, double lng) async {
    final gpsZone = _svc.resolveZoneFromCoords(lat, lng);
    if (gpsZone == null) return null; // can't determine — allow
    if (gpsZone == selectedZone) return null; // match
    return 'Your GPS shows you are in $gpsZone, not $selectedZone. '
        'Select $gpsZone for accurate coverage.';
  }

  void clear() {
    _result = null;
    _resolvedZone = null;
    _resolvedCity = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }
}
