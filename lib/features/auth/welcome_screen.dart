import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/sign_in_screen.dart';
import 'package:nyto_app/features/onboarding/onboarding_flow.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:video_player/video_player.dart';

/// Screen 2 — cinematic welcome: full-bleed media, invite copy, CTA stack.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.preloadedVideo});

  /// Optional controller warmed on splash so video + UI reveal together.
  final VideoPlayerController? preloadedVideo;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _videoAsset = 'assets/video/welcome_loop.mp4';
  static const _bootArt = 'assets/brand/nyto_boot_splash.png';
  static const _bootChannel = MethodChannel('nyto/boot');

  static const _headlines = <String>[
    "You've been invited\nto dinner.",
    'A table is waiting\nfor you.',
    'Tonight, sit with people\nworth meeting.',
  ];

  VideoPlayerController? _video;
  bool _useVideo = false;
  bool _uiReady = false;
  int _headlineIndex = 0;
  Timer? _headlineTimer;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _setSystemUi();
    final pre = widget.preloadedVideo;
    if (pre != null && pre.value.isInitialized) {
      _video = pre;
      _useVideo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealUi();
      });
    } else {
      _bootMedia();
    }
  }

  void _setSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<bool> _hasBundledAsset(String key) async {
    try {
      await rootBundle.load(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _bootMedia() async {
    // Wait for video (or timeout) BEFORE revealing text/CTAs —
    // avoids the ugly "text on black, then video pops in" lag.
    await _tryStartVideo();
    if (!mounted) return;
    _revealUi();
  }

  Future<void> _tryStartVideo() async {
    if (!await _hasBundledAsset(_videoAsset)) return;
    try {
      final controller = VideoPlayerController.asset(_videoAsset);
      await controller
          .initialize()
          .timeout(const Duration(milliseconds: 2800));
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // Paint one video frame before UI fades in.
      setState(() {
        _video = controller;
        _useVideo = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
    } catch (_) {
      // Timeout / missing codec — reveal on ink rather than hang.
    }
  }

  void _revealUi() {
    if (!mounted) return;
    setState(() => _uiReady = true);
    _enter.forward(from: 0);
    _startHeadlineLoop();
    // Soft fade is handled natively on the Image 1 cover.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dropNativeBridge();
    });
  }

  Future<void> _dropNativeBridge() async {
    try {
      await _bootChannel.invokeMethod<void>('dropBridge');
    } catch (_) {}
  }

  void _startHeadlineLoop() {
    _headlineTimer?.cancel();
    _headlineTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted) return;
      setState(() => _headlineIndex = (_headlineIndex + 1) % _headlines.length);
    });
  }

  void _goSignUp() {
    Navigator.of(context).push(onboardingRoute(const OnboardingFlow()));
  }

  void _goSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  @override
  void dispose() {
    _headlineTimer?.cancel();
    _video?.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    final lift = Tween<double>(begin: 18, end: 0).animate(fade);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NytoColors.brandInk,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _MediaBackdrop(
              useVideo: _useVideo,
              video: _video,
            ),
            // Same Image 1 art under native bridge until video is ready.
            if (!_uiReady)
              const Image(
                image: AssetImage(_bootArt),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
            if (_uiReady) const _CinematicScrim(),
            if (_uiReady)
              SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _enter,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _uiReady ? fade.value : 0,
                          child: Transform.translate(
                            offset: Offset(0, lift.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            // Avoid stacking old/new text — clipped leftovers looked like white dots.
                            layoutBuilder: (currentChild, _) =>
                                currentChild ?? const SizedBox.shrink(),
                            transitionBuilder: (child, animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _headlines[_headlineIndex],
                              key: ValueKey(_headlineIndex),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fraunces(
                                fontSize: 34,
                                fontWeight: FontWeight.w500,
                                height: 1.18,
                                letterSpacing: -0.4,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Good people. One table.\nZero planning.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _PrimaryCta(
                            label: 'Get started',
                            onTap: _goSignUp,
                          ),
                          const SizedBox(height: 12),
                          _SecondaryCta(
                            label: 'I already have an account',
                            onTap: _goSignIn,
                          ),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(
                              text: 'By continuing you agree to the ',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.62),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        Colors.white.withValues(alpha: 0.7),
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                                const TextSpan(text: ', '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        Colors.white.withValues(alpha: 0.7),
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Community Guidelines',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        Colors.white.withValues(alpha: 0.7),
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaBackdrop extends StatelessWidget {
  const _MediaBackdrop({
    required this.useVideo,
    required this.video,
  });

  final bool useVideo;
  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    if (useVideo && video != null && video!.value.isInitialized) {
      return ColoredBox(
        color: NytoColors.brandInk,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: video!.value.size.width,
            height: video!.value.size.height,
            child: VideoPlayer(video!),
          ),
        ),
      );
    }

    return const ColoredBox(color: NytoColors.brandInk);
  }
}

class _CinematicScrim extends StatelessWidget {
  const _CinematicScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.16),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.94),
              Colors.black,
            ],
            // Heavy veil under CTAs / legal — video soft-fades out like Timeleft.
            stops: const [0.0, 0.28, 0.48, 0.62, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              NytoColors.ctaSoft,
              NytoColors.cta,
              NytoColors.ctaDeep,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: NytoColors.cta.withValues(alpha: 0.42),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Light glass without BackdropFilter — blur janks hard on emulator GPUs.
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.96),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
