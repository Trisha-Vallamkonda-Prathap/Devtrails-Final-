import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/payout_provider.dart';
import 'providers/policy_provider.dart';
import 'providers/role_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/worker_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // VERY IMPORTANT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 Firebase initialized"); // keep this for now
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => PolicyProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => PayoutProvider()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GigShield',
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
