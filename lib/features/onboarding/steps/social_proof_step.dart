import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Social proof carousel — atmospheric NYTO motion (no spinner / orbit dots).
class SocialProofStep extends StatefulWidget {
  const SocialProofStep({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  State<SocialProofStep> createState() => _SocialProofStepState();
}

class _SocialProofStepState extends State<SocialProofStep>
    with TickerProviderStateMixin {
  static const _total = OnboardingData.totalSteps;

  late final AnimationController _card;
  late final AnimationController _ambient;
  late final AnimationController _shimmer;
  late final AnimationController _title;

  int _index = 0;
  Timer? _holdTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _card = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _title = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _playEnter();
  }

  Future<void> _playEnter() async {
    _exiting = false;
    await _card.forward(from: 0);
    if (!mounted) return;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 2400), _playExit);
  }

  Future<void> _playExit() async {
    if (!mounted) return;
    setState(() => _exiting = true);
    await _card.reverse(from: 1);
    if (!mounted) return;
    setState(() {
      _index = (_index + 1) % OnboardingOptions.socialProof.length;
    });
    HapticFeedback.selectionClick();
    await _playEnter();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _card.dispose();
    _ambient.dispose();
    _shimmer.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = OnboardingOptions.socialProof[_index];
    final titleCurve = CurvedAnimation(
      parent: _title,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );

    return OnboardingScaffold(
      step: 2,
      totalSteps: _total,
      footer: NytoPrimaryButton(
        label: 'Continue',
        onPressed: widget.onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: titleCurve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(titleCurve),
              child: const OnboardingTitle(
                'Different tables. Different nights.',
                subtitle: 'Real nights. Real people. Hyderabad first.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_card, _ambient, _shimmer]),
              builder: (context, _) {
                final raw = _card.value;
                final t = _exiting
                    ? Curves.easeInCubic.transform(raw)
                    : const Cubic(0.16, 1, 0.3, 1).transform(raw);

                final enterDy = 56 * (1 - t);
                final exitDy = -48 * (1 - t);
                final dy = _exiting ? exitDy : enterDy;
                final scale = _exiting
                    ? 0.92 + (0.08 * t)
                    : 0.88 + (0.12 * t);
                final rot = _exiting
                    ? -0.025 * (1 - t)
                    : 0.03 * (1 - t);
                final opacity = t.clamp(0.0, 1.0);
                final blurSigma = (1 - t) * 8;
                final breath = math.sin(_ambient.value * math.pi * 2);

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft aurora — night-sky light, not a loader.
                    _AuroraBloom(phase: _ambient.value, breath: breath),
                    Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: scale,
                            child: blurSigma < 0.4
                                ? _ProofCard(
                                    key: ValueKey(_index),
                                    name: item.name,
                                    city: item.city,
                                    quote: item.quote,
                                    reveal: t,
                                    shimmer: _shimmer.value,
                                  )
                                : ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: blurSigma,
                                      sigmaY: blurSigma,
                                    ),
                                    child: _ProofCard(
                                      key: ValueKey(_index),
                                      name: item.name,
                                      city: item.city,
                                      quote: item.quote,
                                      reveal: t,
                                      shimmer: _shimmer.value,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'A taste of the room — not live chat.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: NytoColors.cream.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slow drifting ice-blue light pools — reads as atmosphere, not a spinner.
class _AuroraBloom extends StatelessWidget {
  const _AuroraBloom({required this.phase, required this.breath});

  final double phase;
  final double breath;

  @override
  Widget build(BuildContext context) {
    final drift = phase * math.pi * 2;
    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(
              28 * math.cos(drift),
              18 * math.sin(drift * 0.85),
            ),
            child: Transform.scale(
              scale: 1.05 + 0.06 * breath,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NytoColors.cta.withValues(alpha: 0.22),
                      NytoColors.ctaSoft.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(
              -36 * math.sin(drift * 0.7),
              24 * math.cos(drift * 0.55),
            ),
            child: Transform.scale(
              scale: 0.95 + 0.05 * -breath,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NytoColors.ctaSoft.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(
              12 * math.sin(drift * 1.1),
              -40 * math.cos(drift * 0.6),
            ),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8EB6FF).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    super.key,
    required this.name,
    required this.city,
    required this.quote,
    required this.reveal,
    required this.shimmer,
  });

  final String name;
  final String city;
  final String quote;
  final double reveal;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final headerT = Curves.easeOutCubic.transform(
      ((reveal - 0.05) / 0.55).clamp(0.0, 1.0),
    );
    final quoteT = Curves.easeOutCubic.transform(
      ((reveal - 0.28) / 0.55).clamp(0.0, 1.0),
    );
    final shineX = -1.2 + shimmer * 2.4;

    return IgnorePointer(
      child: Stack(
        children: [
          NytoGlass.panel(
            selected: true,
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: headerT,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - headerT)),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NytoColors.ctaSoft,
                                NytoColors.cta,
                                NytoColors.ctaDeep,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NytoColors.cta.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            name[0],
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: NytoColors.cream,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                city,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  color: NytoColors.cream
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Opacity(
                  opacity: quoteT,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - quoteT)),
                    child: Text(
                      '"$quote"',
                      style: GoogleFonts.fraunces(
                        fontSize: 19,
                        height: 1.38,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: NytoColors.cream.withValues(alpha: 0.94),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Transform.translate(
                  offset: Offset(shineX * 180, 0),
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.07),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
