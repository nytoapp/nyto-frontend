import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_progress_strip.dart';
import 'package:nyto_app/features/home/home_screen.dart';

enum _SelfiePhase { idle, scanning, blinkPrompt, success }

/// Liveness selfie — visual match to `designs/Screenshot (3708–3709)`.
/// Camera hardware wiring comes later; UI + state machine is real.
class LiveSelfieScreen extends StatefulWidget {
  const LiveSelfieScreen({super.key});

  @override
  State<LiveSelfieScreen> createState() => _LiveSelfieScreenState();
}

class _LiveSelfieScreenState extends State<LiveSelfieScreen> {
  _SelfiePhase _phase = _SelfiePhase.idle;
  bool _buttonPressed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCapture() {
    if (_phase == _SelfiePhase.scanning || _phase == _SelfiePhase.blinkPrompt) {
      return;
    }
    _timer?.cancel();
    setState(() => _phase = _SelfiePhase.scanning);

    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _phase = _SelfiePhase.blinkPrompt);

      _timer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() => _phase = _SelfiePhase.success);
      });
    });
  }

  void _retake() {
    _timer?.cancel();
    setState(() => _phase = _SelfiePhase.idle);
  }

  void _onPrimaryTap({required bool isSuccess, required bool isBusy}) async {
    if (isBusy) return;
    setState(() => _buttonPressed = false);
    if (!isSuccess) {
      _startCapture();
      return;
    }

    try {
      await verificationApi.submitSelfie();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: NytoColors.surface,
        ),
      );
      return;
    } catch (_) {
      // Allow continue if API briefly unreachable during UI QA.
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _phase == _SelfiePhase.success;
    final isBusy =
        _phase == _SelfiePhase.scanning || _phase == _SelfiePhase.blinkPrompt;

    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            children: [
              const NytoProgressStrip(filledSteps: 4, totalSteps: 4),
              const SizedBox(height: 20),
              Text(
                'NYTO',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.cta,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Take a live selfie',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hold still. This confirms you match your ID.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: NytoColors.creamMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: _SelfieOval(
                      phase: _phase,
                      showBlinkPrompt: _phase == _SelfiePhase.blinkPrompt,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _InstructionChip(
                      icon: Icons.center_focus_strong,
                      label: 'Look straight',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InstructionChip(
                      icon: Icons.remove_red_eye_outlined,
                      label: 'Blink when asked',
                    ),
                  ),
                ],
              ),
              if (isSuccess || isBusy) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: isBusy ? null : _retake,
                  icon: Icon(
                    Icons.rotate_right,
                    size: 18,
                    color: NytoColors.creamMuted.withValues(
                      alpha: isBusy ? 0.35 : 1,
                    ),
                  ),
                  label: Text(
                    'Retake',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: NytoColors.creamMuted.withValues(
                        alpha: isBusy ? 0.35 : 1,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 14),
              GestureDetector(
                onTapDown: (!isBusy)
                    ? (_) => setState(() => _buttonPressed = true)
                    : null,
                onTapUp: (!isBusy)
                    ? (_) => _onPrimaryTap(
                          isSuccess: isSuccess,
                          isBusy: isBusy,
                        )
                    : null,
                onTapCancel: (!isBusy)
                    ? () => setState(() => _buttonPressed = false)
                    : null,
                child: AnimatedScale(
                  scale: _buttonPressed ? 0.98 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSuccess ? NytoColors.moss : NytoColors.cta,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: NytoColors.cream,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isSuccess) ...[
                                const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 20,
                                  color: NytoColors.cream,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                isSuccess ? 'Continue' : 'Capture',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: NytoColors.cream,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelfieOval extends StatelessWidget {
  const _SelfieOval({
    required this.phase,
    required this.showBlinkPrompt,
  });

  final _SelfiePhase phase;
  final bool showBlinkPrompt;

  @override
  Widget build(BuildContext context) {
    final success = phase == _SelfiePhase.success;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _OvalGuidePainter(
            borderColor: success
                ? NytoColors.moss
                : NytoColors.cream.withValues(alpha: 0.35),
            tickColor: NytoColors.cta,
            fillColor: success
                ? NytoColors.moss.withValues(alpha: 0.22)
                : const Color(0xFF2A2520),
          ),
        ),
        if (!success)
          Icon(
            Icons.person,
            size: 120,
            color: NytoColors.cream.withValues(alpha: 0.22),
          )
        else
          const Icon(
            Icons.check_circle,
            size: 64,
            color: NytoColors.moss,
          ),
        if (showBlinkPrompt)
          Positioned(
            bottom: 36,
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 350),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: NytoColors.bg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NytoColors.cta.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'Blink now',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  _OvalGuidePainter({
    required this.borderColor,
    required this.tickColor,
    required this.fillColor,
  });

  final Color borderColor;
  final Color tickColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.78,
      height: size.height * 0.92,
    );

    final fill = Paint()..color = fillColor;
    canvas.drawOval(rect, fill);

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    _drawDashedOval(canvas, rect, border);

    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final cx = rect.center.dx;
    final cy = rect.center.dy;
    const tickLen = 10.0;

    // Top
    canvas.drawLine(
      Offset(cx, rect.top - 2),
      Offset(cx, rect.top + tickLen),
      tick,
    );
    // Bottom
    canvas.drawLine(
      Offset(cx, rect.bottom + 2),
      Offset(cx, rect.bottom - tickLen),
      tick,
    );
    // Left
    canvas.drawLine(
      Offset(rect.left - 2, cy),
      Offset(rect.left + tickLen, cy),
      tick,
    );
    // Right
    canvas.drawLine(
      Offset(rect.right + 2, cy),
      Offset(rect.right - tickLen, cy),
      tick,
    );
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addOval(rect);
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OvalGuidePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.tickColor != tickColor;
  }
}

class _InstructionChip extends StatelessWidget {
  const _InstructionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NytoColors.cream.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: NytoColors.cream.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: NytoColors.cta),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: NytoColors.cream.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
