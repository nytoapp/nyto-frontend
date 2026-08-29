import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/media/welcome_video_clip.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';

/// One brand beat: same full-bleed boot art as native → Welcome carousel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bootArt = 'assets/brand/nyto_boot_splash.png';
  static const _bootChannel = MethodChannel('nyto/boot');
  static const _hold = Duration(milliseconds: 1800);

  bool _navigated = false;
  WelcomeCarouselSession? _warmSession;
  bool _ownsSession = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: NytoColors.ground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _holdThenWelcome());
  }

  Future<void> _holdThenWelcome() async {
    if (!mounted || _navigated) return;
    await Future.wait<void>([
      Future<void>.delayed(_hold),
      _warmWelcomeCarousel(),
    ]);
    if (!mounted || _navigated) return;
    await _goWelcome();
  }

  Future<void> _warmWelcomeCarousel() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(fontWeight: FontWeight.w500),
      GoogleFonts.dmSans(fontWeight: FontWeight.w400),
    ]);
    final session = await WelcomeVideoClip.createCarousel();
    if (session == null || !mounted) {
      if (session != null) {
        for (final c in session.controllers) {
          await c.dispose();
        }
      }
      return;
    }
    _warmSession = session;
  }

  Future<void> _goWelcome() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final handedOff = _warmSession;
    _warmSession = null;
    _ownsSession = false;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => WelcomeScreen(
          preloadedSession: handedOff,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 480));
    try {
      await _bootChannel.invokeMethod<void>('dropBridge');
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_ownsSession && _warmSession != null) {
      for (final c in _warmSession!.controllers) {
        unawaited(c.dispose());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: NytoColors.ground,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(_bootArt),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          semanticLabel: 'NYTO',
        ),
      ),
    );
  }
}
