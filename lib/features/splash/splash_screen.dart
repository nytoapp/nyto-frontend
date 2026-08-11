import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:video_player/video_player.dart';

/// One brand beat: same full-bleed boot art as native → Welcome video.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bootArt = 'assets/brand/nyto_boot_splash.png';
  static const _videoAsset = 'assets/video/welcome_loop.mp4';
  static const _bootChannel = MethodChannel('nyto/boot');
  static const _hold = Duration(milliseconds: 1800);

  bool _navigated = false;
  VideoPlayerController? _warmVideo;
  bool _ownsWarmVideo = true;

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
      _warmWelcomeVideo(),
    ]);
    if (!mounted || _navigated) return;
    await _goWelcome();
  }

  Future<void> _warmWelcomeVideo() async {
    try {
      await rootBundle.load(_videoAsset);
      final controller = VideoPlayerController.asset(_videoAsset);
      await controller
          .initialize()
          .timeout(const Duration(milliseconds: 2800));
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _warmVideo = controller;
    } catch (_) {}
  }

  Future<void> _goWelcome() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final handedOff = _warmVideo;
    _warmVideo = null;
    _ownsWarmVideo = false;

    // Keep native bridge up through the route change, then drop.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => WelcomeScreen(preloadedVideo: handedOff),
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
    if (_ownsWarmVideo) {
      _warmVideo?.dispose();
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
