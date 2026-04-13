import '../models/trigger_event.dart';
import '../models/worker.dart';

class TriggerService {
  static double calculatePayout(Worker worker, TriggerEvent event, double hours) {
    final coefficients = {
      TriggerType.rain: 0.50,
      TriggerType.heat: 0.30,
      TriggerType.flood: 1.00,
      TriggerType.closure: 1.00,
      TriggerType.aqi: 0.25,
      TriggerType.cyclone: 1.10,
      TriggerType.flashFlood: 1.20,
    };

    final coefficient = coefficients[event.type] ?? 0.25;
    final raw = (worker.weeklyAvgEarnings / 7) * coefficient * (hours / 12);
    final capped = raw > worker.coverageLimit ? worker.coverageLimit : raw;
    return (capped / 5).roundToDouble() * 5;
  }
}
