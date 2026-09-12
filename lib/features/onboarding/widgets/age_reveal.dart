import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// Editorial age reveal for DOB onboarding.
/// Age is the hero. Geometry is quiet. Copy is minimal.
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
      duration: const Duration(milliseconds: 900),
    )..forward();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AgeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.age != widget.age) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  /// One quiet line. Age stays the hero — never “YOUR CHAPTER” energy.
  String get _line {
    final a = widget.age;
    if (a <= 20) return "You're $a.";
    if (a <= 24) return '$a suits you.';
    if (a <= 29) return "You're $a.";
    if (a <= 34) return '$a — a good age to meet your people.';
    return "You're $a.";
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

    final lightT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    final ringT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.1, 0.65, curve: Cubic(0.22, 1, 0.36, 1)),
    );
    final numberT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.08, 0.55, curve: Cubic(0.22, 1, 0.36, 1)),
    );
    final copyT = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.48, 0.9, curve: Curves.easeOut),
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
                  // Atmospheric light — soft, not neon
                  FadeTransition(
                    opacity: lightT,
                    child: Container(
                      width: stageH * 1.05,
                      height: stageH * 1.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            NytoColors.cta.withValues(
                              alpha: 0.14 + 0.03 * breath,
                            ),
                            NytoColors.ctaSoft.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.38, 1.0],
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
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
                  FadeTransition(
                    opacity: numberT,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1).animate(numberT),
                      child: Transform.translate(
                        offset: const Offset(0, 1.5),
                        child: Text(
                          '${widget.age}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
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
                                  alpha: 0.22 + 0.05 * breath,
                                ),
                                blurRadius: 36,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: copyT,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(copyT),
                child: Text(
                  _line,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    letterSpacing: 0.2,
                    color: NytoColors.cream.withValues(alpha: 0.52),
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

/// Two–three intentional arcs + a couple of light points. Editorial, not HUD.
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
    final spin = phase * math.pi * 2 * 0.012; // barely moves
    final r = math.min(size.width, size.height) * 0.34;

    // Soft core wash
    canvas.drawCircle(
      c,
      r * 0.85,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [
            NytoColors.cta.withValues(alpha: 0.06 * t),
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
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = NytoColors.ctaSoft.withValues(alpha: 0.38 * t),
    );

    // Inner shorter arc (offset, asymmetric)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.78),
      math.pi * 0.15 - spin * 0.6,
      math.pi * 0.85 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.round
        ..color = NytoColors.cream.withValues(alpha: 0.16 * t),
    );

    // Whisper-thin guide ring
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = NytoColors.cream.withValues(alpha: 0.06 * t),
    );

    // Two light points on the outer arc
    for (final frac in [0.08, 0.62]) {
      final a = -math.pi * 0.72 + spin + seed * 0.02 + math.pi * 1.35 * frac;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.drawCircle(
        p,
        2.2 * t,
        Paint()..color = NytoColors.cta.withValues(alpha: 0.75 * t),
      );
      canvas.drawCircle(
        p,
        5.5 * t,
        Paint()..color = NytoColors.cta.withValues(alpha: 0.1 * t),
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
