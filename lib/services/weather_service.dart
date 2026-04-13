import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/trigger_event.dart';

class WeatherService {
  Future<List<TriggerEvent>> fetchConditions(String zone) async {
    if (kUseMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final pulse = DateTime.now().minute % 3 == 0;
      final rainCurrent = pulse ? 26.0 : 14.0;
      return _mock(zone, rainCurrent: rainCurrent, rainTriggered: pulse);
    }

    final uri = Uri.parse('$kBaseUrl/weather/conditions?zone=$zone');
    final res = await http.get(uri);
    final body = jsonDecode(res.body) as List<dynamic>;
    return body
        .map((item) => TriggerEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TriggerEvent>> simulateRain(String zone) async {
    if (kUseMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _mock(
        zone,
        rainCurrent: 26.0,
        rainTriggered: true,
        flashFloodTriggered: true,
      );
    }

    final uri = Uri.parse('$kBaseUrl/weather/simulate-rain?zone=$zone');
    final res = await http.post(uri);
    final body = jsonDecode(res.body) as List<dynamic>;
    return body
        .map((item) => TriggerEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String getAiInsight(List<TriggerEvent> triggers) {
    final anyTriggered = triggers.any((t) => t.isTriggered);
    final anyNear = triggers.any((t) => !t.isTriggered && t.percent > 0.7);
    if (anyTriggered) {
      return 'ALERT: Active disruption. Payout initiated.';
    }
    if (anyNear) {
      return 'Rainfall nearing threshold. Risk in ~40 minutes.';
    }
    return 'Conditions stable. Coverage active.';
  }

  List<TriggerEvent> _mock(
    String zone, {
    required double rainCurrent,
    required bool rainTriggered,
    bool flashFloodTriggered = false,
  }) {
    return [
      TriggerEvent(
        id: 'T1',
        zone: zone,
        unit: 'mm/2hr',
        type: TriggerType.rain,
        currentValue: rainCurrent,
        threshold: 20.0,
        isTriggered: rainTriggered,
        detectedAt: DateTime.now(),
      ),
      TriggerEvent(
        id: 'T2',
        zone: zone,
        unit: '°C',
        type: TriggerType.heat,
        currentValue: 38.0,
        threshold: 42.0,
        isTriggered: false,
        detectedAt: DateTime.now(),
      ),
      TriggerEvent(
        id: 'T3',
        zone: zone,
        unit: 'AQI',
        type: TriggerType.aqi,
        currentValue: 142.0,
        threshold: 400.0,
        isTriggered: false,
        detectedAt: DateTime.now(),
      ),
      TriggerEvent(
        id: 't4',
        zone: zone,
        unit: 'alert level',
        type: TriggerType.cyclone,
        currentValue: 0.0,
        threshold: 1.0,
        isTriggered: false,
        detectedAt: DateTime.now(),
      ),
      TriggerEvent(
        id: 't5',
        zone: zone,
        unit: 'alert level',
        type: TriggerType.flashFlood,
        currentValue: flashFloodTriggered ? 1.0 : 0.0,
        threshold: 1.0,
        isTriggered: flashFloodTriggered,
        detectedAt: DateTime.now(),
      ),
    ];
  }
}
