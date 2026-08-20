import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class EnergyStep extends StatefulWidget {
  const EnergyStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<EnergyStep> createState() => _EnergyStepState();
}

class _EnergyStepState extends State<EnergyStep>
    with TickerProviderStateMixin {
  /// 0 introverted · 1 ambiverted · 2 extroverted
  int _index = 1;

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final AnimationController _facePop;

  @override
  void initState() {
    super.initState();
    final current = widget.data.socialEnergy;
    final i = OnboardingOptions.socialEnergies
        .indexWhere((e) => e.id == current);
    if (i >= 0) _index = i;

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _facePop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    _facePop.dispose();
    super.dispose();
  }

  void _setIndex(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _facePop.forward(from: 0);
  }

  void _go() {
    widget.data.socialEnergy = OnboardingOptions.socialEnergies[_index].id;
    widget.onContinue();
  }

  Color get _faceColor {
    switch (_index) {
      case 0:
        return const Color(0xFF5B6B8C);
      case 2:
        return NytoColors.ctaSoft;
      default:
        return NytoColors.cta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = OnboardingOptions.socialEnergies[_index];
    final enter = CurvedAnimation(
      parent: _enter,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );

    return OnboardingScaffold(
      step: 8,
      totalSteps: OnboardingData.totalSteps,
      footer: FadeTransition(
        opacity: enter,
        child: NytoPrimaryButton(
          label: 'Continue',
          onPressed: _go,
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _pulse, _facePop]),
        builder: (context, _) {
          final pop = const Cubic(0.16, 1, 0.3, 1).transform(_facePop.value);
          final faceScale = 0.86 + (0.14 * pop) + (0.02 * math.sin(_pulse.value * math.pi));
          final glow = 0.28 + 0.1 * _pulse.value;

          return Column(
            children: [
              FadeTransition(
                opacity: enter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(enter),
                  child: const OnboardingTitle(
                    'What’s your social energy like?',
                    subtitle: 'Slide to match how you show up at the table.',
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1.15 + 0.08 * _pulse.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _faceColor.withValues(alpha: glow),
                            _faceColor.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: faceScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      width: 138,
                      height: 138,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _faceColor,
                            Color.lerp(_faceColor, Colors.black, 0.28)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _faceColor.withValues(alpha: 0.42),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: CustomPaint(
                          key: ValueKey(_index),
                          painter: _FacePainter(energy: _index),
                          size: const Size(138, 138),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: const Cubic(0.16, 1, 0.3, 1),
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(_index),
                  children: [
                    Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.hint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.4,
                        color: NytoColors.cream.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: enter,
                child: _EnergySlider(
                  index: _index,
                  accent: _faceColor,
                  onChanged: _setIndex,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Slide or tap to change',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: NytoColors.cream.withValues(alpha: 0.35),
                ),
              ),
              const Spacer(flex: 1),
            ],
          );
        },
      ),
    );
  }
}

class _EnergySlider extends StatelessWidget {
  const _EnergySlider({
    required this.index,
    required this.accent,
    required this.onChanged,
  });

  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbLeft = (index == 0
                ? 0.0
                : index == 1
                    ? width / 2 - 16
                    : width - 32)
            .clamp(0.0, width - 32);
        final fillW = thumbLeft + 16;

        return SizedBox(
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final x = d.localPosition.dx;
              if (x < width / 3) {
                onChanged(0);
              } else if (x > (width * 2) / 3) {
                onChanged(2);
              } else {
                onChanged(1);
              }
            },
            onHorizontalDragUpdate: (d) {
              final x = d.localPosition.dx.clamp(0.0, width);
              if (x < width / 3) {
                onChanged(0);
              } else if (x > (width * 2) / 3) {
                onChanged(2);
              } else {
                onChanged(1);
              }
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: NytoColors.cream.withValues(alpha: 0.1),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  width: fillW.clamp(0.0, width),
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.35),
                        accent,
                      ],
                    ),
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: (i == 0
                            ? 6.0
                            : i == 1
                                ? width / 2 - 5
                                : width - 16)
                        .clamp(0.0, width - 10),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? const Color(0xFF5B6B8C)
                            : i == 1
                                ? NytoColors.cta
                                : NytoColors.ctaSoft,
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: const Cubic(0.16, 1, 0.3, 1),
                  left: thumbLeft,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NytoColors.cream,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({required this.energy});

  final int energy;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final eyeY = size.height * 0.42;
    final eyeGap = size.width * 0.16;
    final eyeR = size.width * 0.048;

    canvas.drawCircle(Offset(cx - eyeGap, eyeY), eyeR, paint);
    canvas.drawCircle(Offset(cx + eyeGap, eyeY), eyeR, paint);

    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6;

    final mouthY = size.height * 0.62;
    final path = Path();
    if (energy == 0) {
      path.moveTo(cx - 18, mouthY + 4);
      path.quadraticBezierTo(cx, mouthY - 4, cx + 18, mouthY + 4);
    } else if (energy == 2) {
      path.moveTo(cx - 22, mouthY - 2);
      path.quadraticBezierTo(cx, mouthY + 16, cx + 22, mouthY - 2);
    } else {
      path.moveTo(cx - 18, mouthY);
      path.quadraticBezierTo(cx, mouthY + 8, cx + 18, mouthY);
    }
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.energy != energy;
}
