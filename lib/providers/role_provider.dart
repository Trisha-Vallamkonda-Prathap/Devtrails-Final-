import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { worker, insurer }

class RoleProvider extends ChangeNotifier {
  static const String _roleKey = 'app_role';

  AppRole _role = AppRole.worker;
  bool _loaded = false;

  AppRole get role => _role;
  bool get isLoaded => _loaded;
  bool get isInsurer => _role == AppRole.insurer;

  Future<void> init() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedRole = prefs.getString(_roleKey);
    _role = storedRole == AppRole.insurer.name ? AppRole.insurer : AppRole.worker;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setRole(AppRole role) async {
    _role = role;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = AppRole.worker;
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }
}