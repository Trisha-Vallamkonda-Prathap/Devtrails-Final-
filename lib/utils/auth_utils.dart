import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/role_provider.dart';
import '../providers/worker_provider.dart';
import '../screens/onboarding/login_screen.dart';

class AuthUtils {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _sessionLoggedInKey = 'session_logged_in';
  static const String _sessionHasPaidSubscriptionKey =
      'session_has_paid_subscription';

  static String userIdFromPhone({required String phone, required AppRole role}) {
    return '${role.name}_$phone';
  }

  static String hasSetPasswordKey(String userId) => 'has_set_password_$userId';

  static String passwordHashKey(String userId) => 'password_hash_$userId';

  static Future<bool> isFirstLogin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetPassword = prefs.getBool(hasSetPasswordKey(userId)) ?? false;
    return !hasSetPassword;
  }

  static Future<void> persistPassword({
    required String userId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = sha256.convert(utf8.encode(password)).toString();

    await _secureStorage.write(key: passwordHashKey(userId), value: hash);
    await prefs.setBool(hasSetPasswordKey(userId), true);
  }

  static Future<void> markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionLoggedInKey, true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionLoggedInKey) ?? false;
  }

  static Future<void> markLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionLoggedInKey, false);
    await prefs.remove(_sessionHasPaidSubscriptionKey);
  }

  static Future<void> logout({
    required BuildContext context,
    required RoleProvider roleProvider,
    WorkerProvider? workerProvider,
  }) async {
    await markLoggedOut();

    if (workerProvider != null) {
      await workerProvider.clearWorker();
    }
    await roleProvider.clearRole();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
