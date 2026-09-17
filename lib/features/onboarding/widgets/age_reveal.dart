import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/widgets/age_band_copy.dart';

/// Editorial age reveal for DOB onboarding.
/// Age is the hero. Geometry is quiet. Copy is the social reading.
class AgeReveal extends StatefulWidget {
  const AgeReveal({super.key, required this.age});

  final int age;

  @override
  State<AgeReveal> createState() => _AgeRevealState();
}

class _AgeRevealState extends State<AgeReveal>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    );
    _startMotion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncReducedMotion();
  }

  @override
  void didUpdateWidget(covariant AgeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.age != widget.age) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  void _startMotion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncReducedMotion();
    });
  }

  void _syncReducedMotion() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _enter.value = 1;
      _life.stop();
      _life.value = 0;
      return;
    }
    if (!_enter.isAnimating && _enter.value < 1) {
      _enter.forward();
    }
    if (!_life.isAnimating) {
      _life.repeat();
    }
  }

  double _ageSize({required bool compact, required int digits}) {
    if (digits >= 3) return compact ? 72.0 : 84.0;
    return compact ? 118.0 : 136.0;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final compact = h < 720;
    final digits = widget.age.toString().length;
    final ageSize = _ageSize(compact: compact, digits: digits);
    final stageH = compact ? 200.0 : 236.0;
    final caption = AgeBandCopy.forAge(widget.age);

    final lightT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    final ringT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.08, 0.7, curve: Cubic(0.22, 1, 0.36, 1)),
    );
    final numberT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.06, 0.58, curve: Cubic(0.22, 1, 0.36, 1)),
    );
    final copyT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.42, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _life]),
      builder: (context, _) {
        final breath = 0.5 + 0.5 * math.sin(_life.value * math.pi * 2);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: stageH,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Stage light — slightly lifted bloom for the reveal moment
                  FadeTransition(
                    opacity: lightT,
                    child: Container(
                      width: stageH * 1.28,
                      height: stageH * 1.28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            NytoColors.cta.withValues(
                              alpha: 0.22 + 0.04 * breath,
                            ),
                            NytoColors.ctaSoft.withValues(
                              alpha: 0.08 + 0.02 * breath,
                            ),
                            NytoColors.cta.withValues(alpha: 0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.32, 0.58, 1.0],
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: lightT,
                    child: Container(
                      width: stageH * 0.92,
                      height: stageH * 0.92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            NytoColors.ctaSoft.withValues(
                              alpha: 0.1 + 0.025 * breath,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: FadeTransition(
                      opacity: ringT,
                      child: CustomPaint(
                        size: Size(stageH * 1.2, stageH),
                        painter: _AgeFramePainter(
                          enter: ringT.value,
                          phase: _life.value,
                          seed: widget.age,
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: numberT,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(numberT),
                      child: Transform.translate(
                        offset: const Offset(0, 1.5),
                        child: Semantics(
                          label: 'Age ${widget.age}',
                          child: Text(
                            '${widget.age}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: ageSize,
                              fontWeight: FontWeight.w400,
                              height: 0.88,
                              letterSpacing: digits >= 3
                                  ? -2.5
                                  : (ageSize > 120 ? -5.5 : -4),
                              color: NytoColors.cream,
                              shadows: [
                                Shadow(
                                  color: NytoColors.cta.withValues(
                                    alpha: 0.28 + 0.06 * breath,
                                  ),
                                  blurRadius: 40,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FadeTransition(
              opacity: copyT,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(copyT),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: compact ? 15.5 : 16.5,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: 0.15,
                      color: NytoColors.cream.withValues(alpha: 0.66),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two–three intentional arcs + light points. Editorial, not HUD.
class _AgeFramePainter extends CustomPainter {
  _AgeFramePainter({
    required this.enter,
    required this.phase,
    required this.seed,
  });

  final double enter;
  final double phase;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final t = Curves.easeOutCubic.transform(enter.clamp(0.0, 1.0));
    final spin = phase * math.pi * 2 * 0.01;
    final r = math.min(size.width, size.height) * 0.34;

    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r * 1.05,
          [
            NytoColors.cta.withValues(alpha: 0.09 * t),
            Colors.transparent,
          ],
        ),
    );

    // Outer incomplete arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 0.72 + spin + seed * 0.02,
      math.pi * 1.35 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = NytoColors.ctaSoft.withValues(alpha: 0.42 * t),
    );

    // Inner shorter arc (offset, asymmetric)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.76),
      math.pi * 0.18 - spin * 0.55,
      math.pi * 0.82 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.round
        ..color = NytoColors.cream.withValues(alpha: 0.18 * t),
    );

    // Whisper guide — incomplete, not a full ring
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 1.1),
      math.pi * 0.95 + spin * 0.3,
      math.pi * 0.95 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..strokeCap = StrokeCap.round
        ..color = NytoColors.cream.withValues(alpha: 0.07 * t),
    );

    // Accent points on the outer arc
    for (final frac in [0.08, 0.62]) {
      final a = -math.pi * 0.72 + spin + seed * 0.02 + math.pi * 1.35 * frac;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.drawCircle(
        p,
        2.15 * t,
        Paint()..color = NytoColors.cta.withValues(alpha: 0.78 * t),
      );
      canvas.drawCircle(
        p,
        5.2 * t,
        Paint()..color = NytoColors.cta.withValues(alpha: 0.12 * t),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AgeFramePainter oldDelegate) {
    return oldDelegate.enter != enter ||
        oldDelegate.phase != phase ||
        oldDelegate.seed != seed;
  }
}
