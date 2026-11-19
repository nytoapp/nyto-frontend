import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/media/welcome_video_clip.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/onboarding/onboarding_flow.dart';
import 'package:video_player/video_player.dart';

/// Signed-in open. Finished profiles go home. An unfinished signup
/// is cleared so the app opens on the welcome screen.
class SessionResume extends StatefulWidget {
  const SessionResume({super.key});

  @override
  State<SessionResume> createState() => _SessionResumeState();
}

class _SessionResumeState extends State<SessionResume> {
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_route());
    });
  }

  Future<void> _route() async {
    if (!mounted || _routed) return;
    try {
      final user = await NytoSession.currentUser();
      if (!mounted || _routed) return;
      if (user != null && onboardingNeedsCompletion(user)) {
        // An unfinished signup must not reopen on the last step.
        try {
          await NytoSession.signOut();
        } catch (_) {}
        if (!mounted || _routed) return;
        _routed = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            opaque: true,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, __, ___, child) => child,
          ),
        );
        return;
      }
    } catch (_) {}
    if (!mounted || _routed) return;
    _routed = true;
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: NytoColors.ground);
  }
}

/// Original NYTO mark. Shown the moment the app opens, then the video.
class NytoOpening extends StatefulWidget {
  const NytoOpening({super.key});

  @override
  State<NytoOpening> createState() => _NytoOpeningState();
}

class _NytoOpeningState extends State<NytoOpening> {
  static const _art = 'assets/brand/nyto_boot_splash.png';
  static const _hold = Duration(seconds: 2);
  Timer? _holdTimer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<Duration> _alreadyOnScreen() async {
    try {
      final ms = await const MethodChannel('nyto/boot').invokeMethod<int>('logoShownMs');
      if (ms == null || ms <= 0) return Duration.zero;
      return Duration(milliseconds: ms);
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> _open() async {
    final already = await _alreadyOnScreen();
    final started = DateTime.now();
    final warmed = await WelcomeVideoClip.warmFirstClip();
    if (!mounted || _left) {
      await warmed?.controller.dispose();
      return;
    }
    final remain = _hold - already - DateTime.now().difference(started);
    if (remain <= Duration.zero) {
      _showVideo(warmed);
      return;
    }
    _holdTimer = Timer(remain, () {
      if (!mounted || _left) return;
      _showVideo(warmed);
    });
  }

  void _showVideo(
    ({VideoPlayerController controller, String assetPath})? warmed,
  ) {
    if (!mounted || _left) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => WelcomeScreen(
          preloadedFirst: warmed?.controller,
          preloadedAssetPath: warmed?.assetPath,
          fromSplashHandoff: warmed != null,
        ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  @override
  void dispose() {
    _left = true;
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: Image(
        image: AssetImage(_art),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
