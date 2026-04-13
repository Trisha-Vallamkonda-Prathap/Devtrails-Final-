import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/worker.dart';

class WorkerProvider extends ChangeNotifier {
  Worker? _worker;
  bool _isOnboarded = false;

  Worker? get worker => _worker;
  bool get isOnboarded => _isOnboarded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final workerJson = prefs.getString('worker_json');
    if (workerJson != null) {
      _worker = Worker.fromJson(jsonDecode(workerJson) as Map<String, dynamic>);
      _isOnboarded = true;
    }
    notifyListeners();
  }

  Future<void> setWorker(Worker worker) async {
    _worker = worker;
    _isOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('worker_json', jsonEncode(worker.toJson()));
    notifyListeners();
  }

  Future<void> clearWorker() async {
    _worker = null;
    _isOnboarded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('worker_json');
    notifyListeners();
  }
}
