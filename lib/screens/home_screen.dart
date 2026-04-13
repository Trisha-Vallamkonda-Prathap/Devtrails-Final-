import 'package:flutter/material.dart';

import 'alerts_screen.dart';
import 'plan_screen.dart';
import 'earnings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> screens = [
    AlertsScreen(),
    const PlanScreen(),
    const EarningsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }
}
