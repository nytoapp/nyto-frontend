import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';

/// Brand splash: hold NYTO, then soft crossfade into Welcome (~2s total).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _wordmark = 'assets/brand/nyto_logo_wordmark.png';
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSplash());
  }

  Future<void> _runSplash() async {
    if (!mounted || _navigated) return;

    // Preload Welcome stills during brand hold.
    // ignore: unawaited_futures
    precacheImage(const AssetImage('assets/video/welcome_01.jpg'), context);
    // ignore: unawaited_futures
    precacheImage(const AssetImage('assets/video/welcome_02.jpg'), context);

    // Hold brand, then soft crossfade ≈ 2s total feel (warm re-open path).
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _navigated) return;
    _goWelcome();
  }

  void _goWelcome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        // Keep splash painted underneath so NYTO soft-dissolves into Welcome.
        opaque: false,
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeIn = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(opacity: fadeIn, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.pureBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Image.asset(
            _wordmark,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
            semanticLabel: 'NYTO — What\'s alive tonight',
          ),
        ),
      ),
    );
  }
}
