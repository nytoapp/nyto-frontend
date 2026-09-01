import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/media/welcome_video_clip.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:video_player/video_player.dart';

/// Exactly 1s full-bleed NYTO (same art as native windowBackground) → instant swap.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _bootArt = 'assets/brand/nyto_boot_splash.png';
  static const _bootChannel = MethodChannel('nyto/boot');
  static const _hold = Duration(milliseconds: 1000);

  bool _navigated = false;
  bool _ownsFirstClip = false;
  bool _nativeReleased = false;
  bool? _sessionResult;
  VideoPlayerController? _preloadedFirst;
  String? _preloadedAssetPath;

  @override
  void initState() {
    super.initState();
    unawaited(
      NytoSession.hasSession().then((value) {
        _sessionResult = value;
      }),
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: NytoColors.ground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmFirstClip());
      unawaited(_holdThenNavigate());
    });
  }

  void _onBootArtPainted() {
    if (_nativeReleased || !mounted) return;
    _nativeReleased = true;
    unawaited(_releaseNativeSplash());
  }

  Future<void> _releaseNativeSplash() async {
    try {
      await _bootChannel.invokeMethod<void>('dropBridge');
    } catch (_) {}
  }

  Future<void> _warmFirstClip() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(fontWeight: FontWeight.w500),
      GoogleFonts.dmSans(fontWeight: FontWeight.w400),
    ]);
    if (!mounted || _navigated) return;

    final warmed = await WelcomeVideoClip.warmFirstClip();
    if (!mounted || _navigated) {
      if (warmed != null) {
        await warmed.controller.dispose();
      }
      return;
    }
    if (warmed != null) {
      _preloadedFirst = warmed.controller;
      _preloadedAssetPath = warmed.assetPath;
      _ownsFirstClip = true;
    }
  }

  Future<void> _holdThenNavigate() async {
    if (!mounted || _navigated) return;
    await Future<void>.delayed(_hold);
    if (!mounted || _navigated) return;

    final hasSession = _sessionResult ?? false;
    if (!mounted || _navigated) return;

    if (hasSession) {
      _goHome();
    } else {
      _goWelcome();
    }
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _disposeUnusedPreload();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  void _goWelcome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final handedFirst = _preloadedFirst;
    final handedPath = _preloadedAssetPath;
    _preloadedFirst = null;
    _preloadedAssetPath = null;
    if (handedFirst != null) {
      _ownsFirstClip = false;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => WelcomeScreen(
          preloadedFirst: handedFirst,
          preloadedAssetPath: handedPath,
          fromSplashHandoff: handedFirst != null,
        ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  void _disposeUnusedPreload() {
    if (_ownsFirstClip && _preloadedFirst != null) {
      unawaited(_preloadedFirst!.dispose());
      _preloadedFirst = null;
      _ownsFirstClip = false;
    }
  }

  @override
  void dispose() {
    _disposeUnusedPreload();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.ground,
      body: SizedBox.expand(
        child: Image(
          image: const AssetImage(_bootArt),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          semanticLabel: 'NYTO',
          frameBuilder: (context, child, frame, wasSyncLoaded) {
            if (frame != null || wasSyncLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onBootArtPainted();
              });
            }
            return child;
          },
        ),
      ),
    );
  }
}
