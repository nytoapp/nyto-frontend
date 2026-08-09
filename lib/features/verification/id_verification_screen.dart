import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_progress_strip.dart';
import 'package:nyto_app/features/verification/live_selfie_screen.dart';

enum IdType { pan, aadhaar, drivingLicence, passport }

extension IdTypeLabel on IdType {
  String get label => switch (this) {
        IdType.pan => 'PAN Card',
        IdType.aadhaar => 'Aadhaar',
        IdType.drivingLicence => 'Driving Licence',
        IdType.passport => 'Passport',
      };
}

/// ID verification — visual match to `designs/Screenshot (3703–3705)`.
class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  IdType? _selected;
  bool _uploaded = false;
  bool _continuePressed = false;
  bool _submitting = false;

  bool get _canContinue =>
      _selected != null && _uploaded && !_submitting;

  String get _docTypeApi => switch (_selected!) {
        IdType.pan => 'PAN',
        IdType.aadhaar => 'AADHAAR',
        IdType.drivingLicence => 'DRIVING_LICENCE',
        IdType.passport => 'PASSPORT',
      };

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() {
      _continuePressed = false;
      _submitting = true;
    });
    try {
      await verificationApi.submitId(documentType: _docTypeApi);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LiveSelfieScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: NytoColors.surface,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit ID. Is the backend running?'),
          backgroundColor: NytoColors.surface,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
              child: NytoProgressStrip(filledSteps: 3, totalSteps: 4),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NYTO',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cta,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Verify your identity',
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: NytoColors.cream,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Everyone at every table is a verified real person. Required before you can book.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.creamMuted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'SELECT ID TYPE',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...IdType.values.map((type) {
                      final selected = _selected == type;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IdOptionTile(
                          label: type.label,
                          selected: selected,
                          onTap: () => setState(() => _selected = type),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Text(
                      'UPLOAD ID PHOTO',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _UploadZone(
                      uploaded: _uploaded,
                      onTap: () => setState(() => _uploaded = !_uploaded),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: NytoColors.cream.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: NytoColors.creamMuted.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your ID is used only for verification and is never shown to other guests.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: NytoColors.creamMuted,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: GestureDetector(
                onTapDown: _canContinue
                    ? (_) => setState(() => _continuePressed = true)
                    : null,
                onTapUp: _canContinue
                    ? (_) => _continue()
                    : null,
                onTapCancel: _canContinue
                    ? () => setState(() => _continuePressed = false)
                    : null,
                child: AnimatedScale(
                  scale: _continuePressed ? 0.98 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _canContinue
                          ? NytoColors.cta
                          : NytoColors.ctaDisabled,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Continue to selfie',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream.withValues(
                          alpha: _canContinue ? 1 : 0.55,
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
    );
  }
}

class _IdOptionTile extends StatelessWidget {
  const _IdOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? NytoColors.cta.withValues(alpha: 0.12)
                : NytoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? NytoColors.cta
                  : NytoColors.cream.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: NytoColors.cta,
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: NytoColors.cream.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.uploaded, required this.onTap});

  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          decoration: BoxDecoration(
            color: uploaded
                ? NytoColors.moss.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: uploaded
                ? Border.all(
                    color: NytoColors.moss.withValues(alpha: 0.7),
                    width: 1.2,
                  )
                : null,
          ),
          child: CustomPaint(
            painter: uploaded
                ? null
                : _DashedBorderPainter(
                    color: NytoColors.cream.withValues(alpha: 0.28),
                    radius: 14,
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    uploaded
                        ? Icons.check_circle_outline
                        : Icons.upload_rounded,
                    size: 28,
                    color: uploaded ? NytoColors.moss : NytoColors.cta,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    uploaded ? 'ID photo ready' : 'Upload ID photo',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uploaded
                        ? 'Tap to replace'
                        : 'JPG, PNG or PDF — max 10 MB',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
