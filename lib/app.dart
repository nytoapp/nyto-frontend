import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';

class NytoApp extends StatelessWidget {
  const NytoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYTO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Native BootActivity already showed Image 1 for 2s.
      home: const WelcomeScreen(),
    );
  }
}
