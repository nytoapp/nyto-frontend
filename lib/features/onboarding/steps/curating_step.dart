import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class CuratingStep extends StatefulWidget {
  const CuratingStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<CuratingStep> createState() => _CuratingStepState();
}

class _CuratingStepState extends State<CuratingStep>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _ring;
  late final AnimationController _panel;

  int _percent = 0;
  int _doneThrough = -1;
  Timer? _timer;
  bool _finished = false;

  static const _lines = [
    'Reading your goals',
    'Reading your energy',
    'Reading your interests',
  ];

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _panel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _run();
  }

  void _run() {
    const totalMs = 2800;
    const tick = 32;
    var elapsed = 0;
    var lastDone = -1;
    _timer = Timer.periodic(const Duration(milliseconds: tick), (t) {
      elapsed += tick;
      final p = Curves.easeOutCubic
          .transform((elapsed / totalMs).clamp(0.0, 1.0));
      final percent = (p * 100).round();
      final done = percent < 34
          ? 0
          : percent < 68
              ? 1
              : 2;
      if (!mounted) return;
      if (done != lastDone) {
        lastDone = done;
        HapticFeedback.selectionClick();
      }
      setState(() {
        _percent = percent;
        _doneThrough = done;
      });
      if (elapsed >= totalMs) {
        t.cancel();
        setState(() {
          _percent = 100;
          _doneThrough = 2;
          _finished = true;
        });
        HapticFeedback.mediumImpact();
        Future<void>.delayed(const Duration(milliseconds: 480), () {
          if (!mounted) return;
          widget.onContinue();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    _ring.dispose();
    _panel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelIn = CurvedAnimation(
      parent: _panel,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );

    return OnboardingScaffold(
      step: 10,
      totalSteps: OnboardingData.totalSteps,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _ring]),
        builder: (context, _) {
          final breath = _breath.value;
          return Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.05 + 0.08 * breath,
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              NytoColors.cta.withValues(
                                alpha: 0.22 + 0.08 * breath,
                              ),
                              NytoColors.ctaSoft.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(148, 148),
                      painter: _ProgressRingPainter(
                        progress: _percent / 100,
                        glow: breath,
                        complete: _finished,
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: GoogleFonts.dmSans(
                        fontSize: _finished ? 30 : 28,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream.withValues(
                          alpha: _finished ? 0.95 : 0.78,
                        ),
                      ),
                      child: Text('$_percent%'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: panelIn,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(panelIn),
                  child: Column(
                    children: [
                      Text(
                        _finished
                            ? 'Your seat vibe is set'
                            : 'We’re seating your vibe',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A quick read so the table feels right.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: NytoColors.cream.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: panelIn,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(panelIn),
                  child: NytoGlass.panel(
                    borderRadius: 18,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      children: [
                        for (var i = 0; i < _lines.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          _CurateLine(
                            label: _lines[i],
                            done: i <= _doneThrough,
                            active: i == _doneThrough && !_finished,
                          ),
                        ],
                      ],
                    ),
                  ),
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

class _CurateLine extends StatelessWidget {
  const _CurateLine({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done
                ? const LinearGradient(
                    colors: [NytoColors.ctaSoft, NytoColors.cta],
                  )
                : null,
            color: done ? null : Colors.transparent,
            border: Border.all(
              color: done
                  ? Colors.transparent
                  : active
                      ? NytoColors.ctaSoft
                      : NytoColors.cream.withValues(alpha: 0.22),
              width: 1.6,
            ),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: NytoColors.cta.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : active
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: NytoColors.ctaSoft,
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: done || active ? FontWeight.w600 : FontWeight.w500,
              color: done || active
                  ? NytoColors.cream
                  : NytoColors.cream.withValues(alpha: 0.38),
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

/// Continuous ice-blue arc — not orbiting dots.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.glow,
    required this.complete,
  });

  final double progress;
  final double glow;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..color = NytoColors.cream.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);

    final sweep = (progress.clamp(0.0, 1.0)) * math.pi * 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: const [
          NytoColors.ctaDeep,
          NytoColors.cta,
          NytoColors.ctaSoft,
          NytoColors.ctaDeep,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = complete ? 6 : 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.6 + glow);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.glow != glow ||
      oldDelegate.complete != complete;
}
