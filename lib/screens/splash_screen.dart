import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/worker_provider.dart';
import '../providers/role_provider.dart';
import '../theme/app_colors.dart';
import '../utils/auth_utils.dart';
import '../widgets/gigshield_logo.dart';
import 'insurer/insurance_dashboard_screen.dart';
import 'main/main_shell.dart';
import 'onboarding/login_screen.dart';
import 'onboarding/terms_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _show = true);
      }
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) {
      return;
    }
    await context.read<RoleProvider>().init();
    final workerProvider = context.read<WorkerProvider>();
    await workerProvider.init();
    if (!mounted) {
      return;
    }
    final isLoggedIn = await AuthUtils.isLoggedIn();
    if (!mounted) {
      return;
    }

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
MaterialPageRoute(builder: (_) => const LoginScreen()),      );
      return;
    }

    final roleProvider = context.read<RoleProvider>();
    if (roleProvider.isInsurer) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute<void>(builder: (_) => const InsuranceDashboardScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute<void>(
        builder: (_) => workerProvider.isOnboarded ? const MainShell() : const TermsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.95, -0.28),
            end: Alignment(0.95, 0.28),
            colors: AppColors.tealGradient,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: _show ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedGigShieldLogo(size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'GigShield',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Protect your earnings. Automatically.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
