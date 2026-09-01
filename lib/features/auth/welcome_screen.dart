import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/media/welcome_video_clip.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/sign_in_screen.dart';
import 'package:nyto_app/features/onboarding/onboarding_flow.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:video_player/video_player.dart';

/// Screen 2 — cinematic welcome: 4-clip carousel, synced copy, CTA stack.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.preloadedSession,
    this.preloadedFirst,
    this.preloadedAssetPath,
    this.fromSplashHandoff = false,
  });

  /// Full carousel warmed on splash (preferred).
  final WelcomeCarouselSession? preloadedSession;

  /// Legacy: first clip only — rest load on welcome.
  final VideoPlayerController? preloadedFirst;
  final String? preloadedAssetPath;

  /// Splash → welcome instant swap: welcome is fully painted on first frame.
  final bool fromSplashHandoff;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _bootArt = 'assets/brand/nyto_boot_splash.png';

  WelcomeCarouselSession? _session;
  WelcomeCarouselController? _carousel;
  bool _useVideo = false;
  bool _uiReady = false;
  bool _ownsSession = true;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _setSystemUi();

    final preSession = widget.preloadedSession;
    if (preSession != null && preSession.controllers.isNotEmpty) {
      _session = preSession;
      _useVideo = true;
      _ownsSession = false;
      _startCarousel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealUi();
      });
    } else if (widget.fromSplashHandoff &&
        widget.preloadedFirst != null &&
        widget.preloadedFirst!.value.isInitialized) {
      _primeHandoffFromSplash(
        widget.preloadedFirst!,
        widget.preloadedAssetPath,
      );
      _uiReady = true;
      _enter.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadFullCarouselInBackground(
          widget.preloadedFirst!,
          widget.preloadedAssetPath,
        ));
      });
    } else if (widget.preloadedFirst != null &&
        widget.preloadedFirst!.value.isInitialized) {
      unawaited(_bootstrapWithFirstClip(
        widget.preloadedFirst!,
        widget.preloadedAssetPath,
      ));
    } else {
      _bootMedia();
    }
  }

  void _primeHandoffFromSplash(
    VideoPlayerController first,
    String? assetPath,
  ) {
    WelcomeClipConfig clip = WelcomeVideoClip.clips.first;
    if (assetPath != null) {
      for (final c in WelcomeVideoClip.clips) {
        if (c.assetPath == assetPath) {
          clip = c;
          break;
        }
      }
    }
    _session = WelcomeCarouselSession(
      clips: [clip],
      controllers: [first],
    );
    _ownsSession = false;
    _useVideo = true;
    _startCarousel();
  }

  Future<void> _bootstrapWithFirstClip(
    VideoPlayerController first,
    String? assetPath,
  ) async {
    final available = await WelcomeVideoClip.availableClips();
    if (!mounted || available.isEmpty) return;

    final clip = available.firstWhere(
      (c) => assetPath == null || c.assetPath == assetPath,
      orElse: () => available.first,
    );

    _session = WelcomeCarouselSession(
      clips: [clip],
      controllers: [first],
    );
    _ownsSession = false;
    _useVideo = true;
    _startCarousel();

    if (!mounted) return;
    _revealUi();

    unawaited(_loadFullCarouselInBackground(first, assetPath));
  }

  Future<void> _loadFullCarouselInBackground(
    VideoPlayerController first,
    String? assetPath,
  ) async {
    final full = await WelcomeVideoClip.createCarousel(
      preloadedFirst: first,
      preloadedAssetPath: assetPath,
    );
    if (!mounted || full == null || full.controllers.length <= 1) return;

    final previousCarousel = _carousel;
    _session = full;
    _ownsSession = true;
    _startCarousel();
    previousCarousel?.dispose();
    setState(() {});
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

  Future<void> _bootMedia() async {
    await _loadCarousel(
      preloadedFirst: widget.preloadedFirst,
      preloadedAssetPath: widget.preloadedAssetPath,
    );
    if (!mounted) return;
    _revealUi();
  }

  Future<void> _loadCarousel({
    VideoPlayerController? preloadedFirst,
    String? preloadedAssetPath,
  }) async {
    final session = await WelcomeVideoClip.createCarousel(
      preloadedFirst: preloadedFirst,
      preloadedAssetPath: preloadedAssetPath,
    );
    if (session == null || !mounted) {
      if (session != null) {
        await _disposeSession(session, keep: preloadedFirst);
      }
      return;
    }
    _session = session;
    _startCarousel();
    setState(() => _useVideo = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  void _startCarousel() {
    final session = _session;
    if (session == null) return;
    _carousel?.dispose();
    _carousel = WelcomeCarouselController(
      session: session,
      vsync: this,
    );
  }

  Future<void> _disposeSession(
    WelcomeCarouselSession session, {
    VideoPlayerController? keep,
  }) async {
    for (final c in session.controllers) {
      if (c != keep) {
        await c.dispose();
      }
    }
  }

  void _revealUi() {
    if (!mounted) return;
    setState(() => _uiReady = true);
    _enter.forward(from: 0);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _carousel?.resumePlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carousel?.dispose();
    if (_ownsSession && _session != null) {
      unawaited(_disposeSession(_session!));
    }
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    final lift = Tween<double>(begin: 18, end: 0).animate(fade);
    final carousel = _carousel;

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
            if (carousel != null && _useVideo)
              _CarouselBackdrop(carousel: carousel)
            else
              const ColoredBox(color: NytoColors.brandInk),
            if (!_uiReady && !widget.fromSplashHandoff)
              const Image(
                image: AssetImage(_bootArt),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
            if (_uiReady) const _CinematicScrim(),
            if (_uiReady && carousel != null)
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
                            _SlideCopy(carousel: carousel),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
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

class _CarouselBackdrop extends StatelessWidget {
  const _CarouselBackdrop({required this.carousel});

  final WelcomeCarouselController carousel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: carousel.crossfade,
      builder: (context, _) {
        final t = carousel.isTransitioning ? carousel.crossfade.value : 0.0;
        final active = carousel.activeIndex;
        final incoming = carousel.incomingIndex;

        return Stack(
          fit: StackFit.expand,
          children: [
            _VideoFill(
              controller: carousel.controllers[active],
              opacity: 1 - t,
            ),
            if (carousel.isTransitioning)
              _VideoFill(
                controller: carousel.controllers[incoming],
                opacity: t,
              ),
          ],
        );
      },
    );
  }
}

class _VideoFill extends StatelessWidget {
  const _VideoFill({
    required this.controller,
    required this.opacity,
  });

  final VideoPlayerController controller;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: NytoColors.brandInk);
    }

    final vw = controller.value.size.width;
    final vh = controller.value.size.height;
    if (vw <= 0 || vh <= 0) {
      return const ColoredBox(color: NytoColors.brandInk);
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: ColoredBox(
        color: NytoColors.brandInk,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: vw,
              height: vh,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}

/// Copy synced to video crossfade — swaps at 50% (same moment as dominant video).
class _SlideCopy extends StatelessWidget {
  const _SlideCopy({required this.carousel});

  final WelcomeCarouselController carousel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: carousel.crossfade,
      builder: (context, _) {
        final clip = carousel.clips[carousel.displayClipIndex];

        return _CopyBlock(
          key: ValueKey(carousel.displayClipIndex),
          headline: clip.headline,
          caption: clip.caption,
        );
      },
    );
  }
}

class _CopyBlock extends StatelessWidget {
  const _CopyBlock({
    super.key,
    required this.headline,
    required this.caption,
  });

  final String headline;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: 34,
            fontWeight: FontWeight.w500,
            height: 1.18,
            letterSpacing: -0.4,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.86),
          ),
        ),
      ],
    );
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
