import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// One quote at a time — exits fully before the next enters. No overlap.
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
    with SingleTickerProviderStateMixin {
  static const _total = 8;
  late final AnimationController _motion;
  int _index = 0;
  Timer? _holdTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _playEnter();
  }

  Future<void> _playEnter() async {
    _exiting = false;
    await _motion.forward(from: 0);
    if (!mounted) return;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 2100), _playExit);
  }

  Future<void> _playExit() async {
    if (!mounted) return;
    setState(() => _exiting = true);
    await _motion.reverse(from: 1);
    if (!mounted) return;
    setState(() {
      _index = (_index + 1) % OnboardingOptions.socialProof.length;
    });
    await _playEnter();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = OnboardingOptions.socialProof[_index];

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
          const OnboardingTitle(
            'Different tables. Different nights.',
            subtitle: 'Real nights. Real people. Hyderabad first.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: AnimatedBuilder(
              animation: _motion,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_motion.value);
                // Enter: from below. Exit: continue upward (mirror via _exiting).
                final dy = _exiting
                    ? -42 * (1 - t)
                    : 42 * (1 - t);
                final opacity = t;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              NytoColors.brandMagenta.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: _ProofCard(
                          key: ValueKey(_index),
                          name: item.name,
                          city: item.city,
                          quote: item.quote,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(OnboardingOptions.socialProof.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: active
                      ? NytoColors.brandPink
                      : NytoColors.cream.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
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

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    super.key,
    required this.name,
    required this.city,
    required this.quote,
  });

  final String name;
  final String city;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: NytoGlass.panel(
        selected: true,
        borderRadius: 22,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        NytoColors.ctaSoft,
                        NytoColors.cta,
                      ],
                    ),
                  ),
                  child: Text(
                    name[0],
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 17,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: NytoColors.cream,
                        ),
                      ),
                      Text(
                        city,
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: NytoColors.cream.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '"$quote"',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: NytoColors.cream.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
