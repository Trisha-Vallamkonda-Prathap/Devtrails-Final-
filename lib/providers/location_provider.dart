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

  /// Medium-risk (trajectory jump / sensor mismatch) — warn but don't block
  bool get hasMediumRisk => _result?.hasMediumRisk == true;
  bool get hasLowRisk => _result?.hasLowRisk == true;

  String? get resolvedZone => _resolvedZone;
  String? get resolvedCity => _resolvedCity;
  double? get lat => _result?.lat;
  double? get lng => _result?.lng;
  double? get accuracy => _result?.accuracy;

  /// User-facing message: spoof warning OR medium/low risk hint OR null
  String? get errorMessage {
    if (_result == null) return null;
    if (_result!.isSpoofDetected) return _result!.errorMessage;
    if (_result!.riskReason != null) return _result!.riskReason;
    return null;
  }

  Future<void> fetchLocation() async {
    _loading = true;
    notifyListeners();

    _result = await _svc.getCurrentLocation();

    if (_result!.isSuccess) {
      _resolvedZone =
          _svc.resolveZoneFromCoords(_result!.lat!, _result!.lng!);
      _resolvedCity =
          _svc.resolveCityFromCoords(_result!.lat!, _result!.lng!);

      // Auto-create dynamic zone if no match found
      if (_resolvedZone == null && _result!.address != null) {
        _resolvedZone =
            _result!.address!.neighbourhood ?? 'Custom Zone';
        _resolvedCity = _result!.address!.city ?? 'Unknown City';
      }
    }

    _loading = false;
    notifyListeners();
  }

  /// Validate manually selected zone against GPS.
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
    notifyListeners();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }
}