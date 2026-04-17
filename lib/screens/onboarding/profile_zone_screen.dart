import 'package:flutter/material.dart';

import 'profile_setup_screen.dart';

class ProfileZoneScreen extends StatelessWidget {
  const ProfileZoneScreen({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return ProfileSetupScreen(phone: phone);
  }
}
