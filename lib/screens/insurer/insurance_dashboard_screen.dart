import 'package:flutter/material.dart';

import '../../data/insurer/mock_data.dart';
import '../../theme/insurer_colors.dart';
import 'fraud_alerts_screen.dart';
import 'insurer_home_screen.dart';
import 'payout_analytics_screen.dart';
import 'zone_risk_heatmap_screen.dart';
import 'worker_management_screen.dart';

class InsuranceDashboardScreen extends StatefulWidget {
  const InsuranceDashboardScreen({super.key});

  @override
  State<InsuranceDashboardScreen> createState() => _InsuranceDashboardScreenState();
}

class _InsuranceDashboardScreenState extends State<InsuranceDashboardScreen> {
  int _index = 0;

  static const _tabs = [
    InsurerHomeScreen(),
    WorkerManagementScreen(),
    FraudAlertsScreen(),
    ZoneRiskHeatmapScreen(),
    PayoutAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsurerColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) => setState(() => _index = value),
                    backgroundColor: InsurerColors.background,
                    indicatorColor: InsurerColors.accent.withValues(alpha: 0.2),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      _railDestination(Icons.dashboard_outlined, 'Home'),
                      _railDestination(Icons.groups_outlined, 'Workers'),
                      NavigationRailDestination(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.warning_amber_outlined),
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: InsurerColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        label: const Text('Alerts'),
                      ),
                      _railDestination(Icons.map_outlined, 'Map'),
                      _railDestination(Icons.bar_chart_outlined, 'Analytics'),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: InsurerColors.border),
                  Expanded(child: _tabs[_index]),
                ],
              );
            }

            return Scaffold(
              backgroundColor: InsurerColors.background,
              body: IndexedStack(index: _index, children: _tabs),
              bottomNavigationBar: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: InsurerColors.surface,
                  indicatorColor: InsurerColors.accent.withValues(alpha: 0.2),
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(color: InsurerColors.textSecondary, fontSize: 11),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => setState(() => _index = value),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
                    NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Workers'),
                    NavigationDestination(
                      icon: _AlertIcon(),
                      label: 'Alerts',
                    ),
                    NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
                    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Analytics'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  NavigationRailDestination _railDestination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon();

  @override
  Widget build(BuildContext context) {
    final count = mockFraudAlerts.length;
    final label = count > 9 ? '9+' : count.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.warning_amber_outlined),
        Positioned(
          right: -7,
          top: -7,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: InsurerColors.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}