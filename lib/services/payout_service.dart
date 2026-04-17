import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/payout.dart';
import '../models/trigger_event.dart';

class PayoutService {
  static List<Payout> getMockHistory() {
    final now = DateTime.now();
    return [
      Payout(
        id: 'P001',
        workerId: 'W001',
        zone: 'Hebbal',
        description: 'Heavy rain 26mm/2hr',
        triggerType: TriggerType.rain,
        amount: 390,
        status: PayoutStatus.accepted,
        triggeredAt: now,
        transactionId: 'GS-2024149',
      ),
      Payout(
        id: 'P002',
        workerId: 'W001',
        zone: 'Hebbal',
        description: 'Heat index 43.2°C',
        triggerType: TriggerType.heat,
        amount: 175,
        status: PayoutStatus.accepted,
        triggeredAt: now.subtract(const Duration(hours: 26)),
        transactionId: 'GS-2024148',
      ),
      Payout(
        id: 'P003',
        workerId: 'W001',
        zone: 'Hebbal',
        description: 'Local zone closure',
        triggerType: TriggerType.closure,
        amount: 215,
        status: PayoutStatus.declined,
        triggeredAt: now.subtract(const Duration(hours: 72)),
      ),
      Payout(
        id: 'P004',
        workerId: 'W001',
        zone: 'Hebbal',
        description: 'Heavy rain 29mm/2hr',
        triggerType: TriggerType.rain,
        amount: 324,
        status: PayoutStatus.accepted,
        triggeredAt: now.subtract(const Duration(hours: 120)),
        transactionId: 'GS-2024131',
      ),
    ];
  }

  Future<Map<String, dynamic>> process(String payoutId, String workerId) async {
    if (kUseMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final rng = Random();
      return {
        'status': 'accepted',
        'transaction_id': 'GS-${1000000 + rng.nextInt(9000000)}',
        'upi_ref': 'UPI${100000000 + rng.nextInt(900000000)}',
      };
    }

    final uri = Uri.parse('$kBaseUrl/payout/accept');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'payout_id': payoutId, 
        'worker_id': workerId,
        'account_number': '1234567890', // Replace with actual
        'ifsc': 'HDFC0001234', // Replace with actual
        'name': 'John Doe', // Replace with actual
        'contact': '9999999999', // Replace with actual
        'email': 'john@example.com' // Replace with actual
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
