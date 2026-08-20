import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class WeKnowYouStep extends StatefulWidget {
  const WeKnowYouStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<WeKnowYouStep> createState() => _WeKnowYouStepState();
}

class _WeKnowYouStepState extends State<WeKnowYouStep>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _breath;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _breath.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  String get _name {
    final n = widget.data.firstName.trim();
    return n.isEmpty ? 'there' : n;
  }

  String get _blurb {
    final topic = widget.data.interestLabelHint;
    final energy = widget.data.socialEnergy;
    if (energy == 'introverted') {
      return 'We’ll find a table that still leaves room to breathe — and you’ll probably end up talking about $topic.';
    }
    if (energy == 'extroverted') {
      return 'We’ll seat you where the night opens up — you’ll probably land on $topic before dessert.';
    }
    return 'We’ll find the best group for you. You’ll probably end up talking about $topic.';
  }

  @override
  Widget build(BuildContext context) {
    final checkT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Cubic(0.16, 1, 0.3, 1)),
    );
    final titleT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.22, 0.7, curve: Cubic(0.16, 1, 0.3, 1)),
    );
    final cardT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.4, 1.0, curve: Cubic(0.16, 1, 0.3, 1)),
    );

    return OnboardingScaffold(
      step: 11,
      totalSteps: OnboardingData.totalSteps,
      footer: FadeTransition(
        opacity: cardT,
        child: NytoPrimaryButton(
          label: 'Continue',
          onPressed: widget.onContinue,
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _breath, _shimmer]),
        builder: (context, _) {
          final breath = _breath.value;
          final shineX = -1.2 + _shimmer.value * 2.4;

          return Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: checkT,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1).animate(checkT),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.1 + 0.08 * breath,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                NytoColors.cta.withValues(
                                  alpha: 0.28 + 0.1 * breath,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
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
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: (1 - checkT.value) * -0.35,
                          child: const Icon(
                            Icons.check_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: titleT,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(titleT),
                  child: Text(
                    'Hey $_name, we know you a little better now',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: NytoColors.cream,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: cardT,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(cardT),
                  child: Stack(
                    children: [
                      NytoGlass.panel(
                        borderRadius: 18,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Text(
                          _blurb,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            height: 1.45,
                            color: NytoColors.cream.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Transform.translate(
                              offset: Offset(shineX * 160, 0),
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  width: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.06),
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
                ),
              ),
              const Spacer(flex: 3),
            ],
          );
        },
      ),
    );
  }
}
