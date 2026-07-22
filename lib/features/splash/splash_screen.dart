import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1512),
              Color(0xFF2F4F3E),
              Color(0xFFC45C26),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'NYTO',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: AppTheme.cream,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}
