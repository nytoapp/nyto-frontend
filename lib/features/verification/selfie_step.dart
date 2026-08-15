import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/kyc/kyc_session.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Live selfie capture for safety — frontend only until KYC backend.
class SelfieStep extends StatefulWidget {
  const SelfieStep({
    super.key,
    required this.data,
    required this.onContinue,
    this.standalone = false,
  });

  final OnboardingData data;
  final VoidCallback onContinue;
  final bool standalone;

  @override
  State<SelfieStep> createState() => _SelfieStepState();
}

class _SelfieStepState extends State<SelfieStep> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _captured = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final cam = front.isNotEmpty
          ? front.first
          : (cameras.isEmpty ? null : cameras.first);
      if (cam == null) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }
      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _saving) return;
    setState(() => _saving = true);
    try {
      await c.takePicture();
      if (!mounted) return;
      setState(() {
        _captured = true;
        _saving = false;
        widget.data.selfieCaptured = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not capture. Try again.';
      });
    }
  }

  Future<void> _finish() async {
    await KycSession.markVerified();
    widget.onContinue();
  }

  /// Dev fallback when camera can’t open (emulator / denied).
  Future<void> _mockCapture() async {
    setState(() {
      _captured = true;
      widget.data.selfieCaptured = true;
      _error = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller?.value.isInitialized == true;

    return OnboardingScaffold(
      step: 10,
      totalSteps: OnboardingData.totalSteps,
      showProgress: !widget.standalone,
      footer: NytoPrimaryButton(
        label: _captured
            ? 'Finish verification'
            : (_saving ? 'Capturing…' : 'Take selfie'),
        enabled: _captured || (ready && !_saving) || _error != null,
        onPressed: _captured
            ? _finish
            : (_error != null
                ? _mockCapture
                : (ready && !_saving ? _capture : null)),
      ),
      child: ListView(
        children: [
          const OnboardingTitle(
            'Live selfie',
            subtitle:
                'One clear face photo for table safety. Not shown as your public profile.',
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_initializing)
                      const Center(
                        child: CircularProgressIndicator(
                          color: NytoColors.ctaSoft,
                        ),
                      )
                    else if (ready)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize?.height ?? 480,
                          height: _controller!.value.previewSize?.width ?? 640,
                          child: CameraPreview(_controller!),
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error ?? 'Camera not ready',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: NytoColors.cream.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    // Face guide oval
                    if (!_captured)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _FaceGuidePainter(),
                        ),
                      ),
                    if (_captured)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: NytoColors.ctaSoft,
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Selfie captured',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: NytoColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null && !ready) ...[
            const SizedBox(height: 14),
            NytoGlass.panel(
              borderRadius: 14,
              padding: const EdgeInsets.all(14),
              child: Text(
                '$_error\nTap the button below to continue with a demo selfie for now.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.4,
                  color: NytoColors.cream.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
          if (_captured) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _captured = false),
              child: Text(
                'Retake',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: NytoColors.ctaSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.35);
    final clear = Path()
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.42),
          width: size.width * 0.62,
          height: size.height * 0.48,
        ),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(clear, overlay);

    final ring = Paint()
      ..color = NytoColors.ctaSoft.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: size.width * 0.62,
        height: size.height * 0.48,
      ),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
