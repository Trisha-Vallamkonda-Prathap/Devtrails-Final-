import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/trigger_event.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  List<TriggerEvent> _triggers = <TriggerEvent>[];
  String _insight = '';
  bool _loading = false;
  Timer? _timer;

  List<TriggerEvent> get triggers => _triggers;
  String get insight => _insight;
  bool get loading => _loading;

  TriggerEvent? get mostUrgent {
    if (_triggers.isEmpty) {
      return null;
    }
    final sorted = List<TriggerEvent>.from(_triggers)
      ..sort((a, b) => b.percent.compareTo(a.percent));
    return sorted.first;
  }

  Future<void> fetch(String zone) async {
    _loading = true;
    notifyListeners();

    _triggers = await _service.fetchConditions(zone);
    _insight = _service.getAiInsight(_triggers);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) async {
      _triggers = await _service.fetchConditions(zone);
      _insight = _service.getAiInsight(_triggers);
      notifyListeners();
    });

    _loading = false;
    notifyListeners();
  }

  Future<void> simulateRain(String zone) async {
    _triggers = await _service.simulateRain(zone);
    _insight = _service.getAiInsight(_triggers);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
