import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/kyc/kyc_session.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// DigiLocker verify — UI flow until partner API is wired.
class DigilockerStep extends StatefulWidget {
  const DigilockerStep({
    super.key,
    required this.data,
    required this.onContinue,
    this.standalone = false,
  });

  final OnboardingData data;
  final VoidCallback onContinue;
  final bool standalone;

  @override
  State<DigilockerStep> createState() => _DigilockerStepState();
}

class _DigilockerStepState extends State<DigilockerStep> {
  bool _linking = false;
  bool _linked = false;

  @override
  void initState() {
    super.initState();
    _linked = widget.data.digilockerLinked;
  }

  Future<void> _connect() async {
    setState(() => _linking = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await KycSession.markDigilockerLinked();
    setState(() {
      _linking = false;
      _linked = true;
      widget.data.digilockerLinked = true;
    });
  }

  void _showNoDigilockerHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NytoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Don't have DigiLocker?",
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You don’t need the DigiLocker app installed. A free DigiLocker account works in the browser at digilocker.gov.in.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  color: NytoColors.cream.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'If you still can’t use it, we’ll add another verify path later (PAN / partner KYC). For now DigiLocker is the main check.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  color: NytoColors.cream.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: NytoPrimaryButton(
                  label: 'Got it',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 13,
      totalSteps: OnboardingData.totalSteps,
      showProgress: !widget.standalone,
      footer: NytoPrimaryButton(
        label: _linked ? 'Continue' : (_linking ? 'Connecting…' : 'Continue with DigiLocker'),
        enabled: _linked || !_linking,
        onPressed: _linked
            ? widget.onContinue
            : (_linking ? null : _connect),
      ),
      child: ListView(
        children: [
          const OnboardingTitle(
            'Verify with DigiLocker',
            subtitle:
                'We confirm you’re real via DigiLocker — we don’t store your Aadhaar or PAN.',
          ),
          const SizedBox(height: 28),
          NytoGlass.panel(
            borderRadius: 22,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [NytoColors.ctaSoft, NytoColors.cta],
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Government-backed ID check',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          color: NytoColors.cream,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Bullet('Sign in to DigiLocker and approve NYTO'),
                _Bullet('We only keep a verified status — not your ID numbers'),
                _Bullet('Required before you can reserve a table'),
              ],
            ),
          ),
          if (!_linked) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showNoDigilockerHelp,
              child: Text(
                "Don't have DigiLocker?",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: NytoColors.ctaSoft,
                ),
              ),
            ),
          ],
          if (_linked) ...[
            const SizedBox(height: 20),
            NytoGlass.panel(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: NytoColors.ctaSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DigiLocker linked (UI preview). Real connection comes later.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.35,
                        color: NytoColors.cream.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: NytoColors.ctaSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                color: NytoColors.cream.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
