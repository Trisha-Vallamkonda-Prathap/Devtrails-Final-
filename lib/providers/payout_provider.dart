import 'package:flutter/foundation.dart';

import '../models/payout.dart';
import '../models/trigger_event.dart';
import '../models/worker.dart';
import '../services/payout_service.dart';
import '../services/trigger_service.dart';

class PayoutProvider extends ChangeNotifier {
  final PayoutService _service = PayoutService();
  final Map<String, DateTime> _autoTriggerAt = <String, DateTime>{};

  List<Payout> _history = <Payout>[];
  Payout? _pending;
  bool _loading = false;

  List<Payout> get history => _history;
  Payout? get pending => _pending;
  bool get loading => _loading;

  double get totalProtected => _history
      .where((p) => p.status == PayoutStatus.accepted)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get thisWeek {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return _history
        .where((p) =>
            p.status == PayoutStatus.accepted && p.triggeredAt.isAfter(start))
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  bool get hasPending => _pending != null;

  void init() {
    _history = PayoutService.getMockHistory();
    notifyListeners();
  }

  void syncAutoTrigger(Worker worker, List<TriggerEvent> triggers) {
    final TriggerEvent? event = triggers.where((t) => t.isTriggered).cast<TriggerEvent?>().firstWhere(
          (t) => t != null,
          orElse: () => null,
        );
    if (event == null) {
      return;
    }

    final now = DateTime.now();
    final key = '${worker.id}:${worker.fullZone}:${event.type.name}';
    final lastTriggeredAt = _autoTriggerAt[key];
    if (lastTriggeredAt != null && now.difference(lastTriggeredAt) < const Duration(minutes: 30)) {
      return;
    }

    if (_pending != null && _pending!.zone == worker.fullZone && _pending!.triggerType == event.type) {
      return;
    }

    final amount = TriggerService.calculatePayout(worker, event, 6.5);
    _pending = Payout(
      id: 'P-AUTO-${now.millisecondsSinceEpoch}',
      workerId: worker.id,
      zone: worker.fullZone,
      description: '${event.displayName} crossed ${event.threshold}${event.unit}',
      triggerType: event.type,
      amount: amount,
      status: PayoutStatus.pending,
      triggeredAt: now,
    );
    _autoTriggerAt[key] = now;
    notifyListeners();
  }

  void triggerMock(Worker worker) {
    final rainEvent = TriggerEvent(
      id: 'T-LIVE',
      zone: worker.fullZone,
      unit: 'mm/2hr',
      type: TriggerType.rain,
      currentValue: 26,
      threshold: 20,
      isTriggered: true,
      detectedAt: DateTime.now(),
    );
    final amount = TriggerService.calculatePayout(worker, rainEvent, 6.5);
    _pending = Payout(
      id: 'P-LIVE',
      workerId: worker.id,
      zone: worker.fullZone,
      description: 'Heavy rain 26mm/2hr',
      triggerType: TriggerType.rain,
      amount: amount,
      status: PayoutStatus.pending,
      triggeredAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<bool> accept(String id) async {
    if (_pending == null) {
      return false;
    }
    _loading = true;
    notifyListeners();

    final result = await _service.process(id, _pending!.workerId);
    final accepted = _pending!.copyWith(
      status: PayoutStatus.accepted,
      transactionId: result['transaction_id'] as String?,
      settledAt: DateTime.now(),
    );
    _history = <Payout>[accepted, ..._history.where((p) => p.id != accepted.id)];
    _pending = null;

    _loading = false;
    notifyListeners();
    return true;
  }

  void decline(String id) {
    _pending = null;
    notifyListeners();
  }
}
