import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class VerificationSuccessScreen extends StatefulWidget {
  const VerificationSuccessScreen({super.key});

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _enter,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );

    return OnboardingScaffold(
      step: 1,
      totalSteps: 1,
      showProgress: false,
      footer: NytoPrimaryButton(
        label: 'Continue',
        onPressed: () => Navigator.of(context).pop(true),
      ),
      child: FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
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
                child: const Icon(
                  Icons.verified_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'You’re verified',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 12),
              NytoGlass.panel(
                borderRadius: 18,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Text(
                  'Selfie and DigiLocker are done. You’re cleared to reserve a seat at the table.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    height: 1.45,
                    color: NytoColors.cream.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
