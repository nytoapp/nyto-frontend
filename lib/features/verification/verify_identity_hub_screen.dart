import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/kyc/kyc_session.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';
import 'package:nyto_app/features/verification/digilocker_step.dart';
import 'package:nyto_app/features/verification/selfie_step.dart';
import 'package:nyto_app/features/verification/verification_success_screen.dart';

/// Opens the verification gate. Returns `true` when fully verified.
Future<bool> openVerificationGate(
  BuildContext context, {
  required String reason,
}) async {
  if (await KycSession.isVerified()) return true;
  if (!context.mounted) return false;

  final result = await Navigator.of(context).push<bool>(
    onboardingRoute(
      VerifyIdentityHubScreen(
        reason: reason,
        gateMode: true,
      ),
    ),
  );
  return result == true || await KycSession.isVerified();
}

/// Profile + booking hub — selfie first, then DigiLocker. UI/demo only.
class VerifyIdentityHubScreen extends StatefulWidget {
  const VerifyIdentityHubScreen({
    super.key,
    this.reason =
        'We verify every guest before a table — so strangers stay safe.',
    this.gateMode = false,
  });

  final String reason;
  final bool gateMode;

  @override
  State<VerifyIdentityHubScreen> createState() =>
      _VerifyIdentityHubScreenState();
}

class _VerifyIdentityHubScreenState extends State<VerifyIdentityHubScreen> {
  bool _loading = true;
  bool _selfie = false;
  bool _digi = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final selfie = await KycSession.isSelfieDone();
    final digi = await KycSession.isDigilockerLinked();
    final verified = await KycSession.isVerified();
    if (!mounted) return;
    setState(() {
      _selfie = selfie;
      _digi = digi;
      _verified = verified;
      _loading = false;
    });
  }

  String get _statusTitle {
    if (_verified) return 'You’re verified';
    if (_selfie || _digi) return 'Almost there';
    return 'Verify your identity';
  }

  String get _statusSubtitle {
    if (_verified) {
      return 'You’re cleared to reserve tables on NYTO.';
    }
    if (_selfie && !_digi) {
      return 'Selfie done. Finish DigiLocker to complete verification.';
    }
    if (!_selfie && _digi) {
      return 'DigiLocker done. Finish your selfie to complete verification.';
    }
    return widget.reason;
  }

  Future<void> _runSelfie() async {
    final data = OnboardingData();
    await Navigator.of(context).push(
      onboardingRoute(
        SelfieStep(
          data: data,
          standalone: true,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
    await _refresh();
    if (!mounted) return;
    if (_selfie && !_digi) {
      await _runDigilocker();
    } else if (_verified) {
      await _finishIfVerified();
    }
  }

  Future<void> _runDigilocker() async {
    final data = OnboardingData()..digilockerLinked = _digi;
    await Navigator.of(context).push(
      onboardingRoute(
        DigilockerStep(
          data: data,
          standalone: true,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
    await _refresh();
    if (!mounted) return;
    await _finishIfVerified();
  }

  Future<void> _finishIfVerified() async {
    if (!await KycSession.isVerified()) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      onboardingRoute(const VerificationSuccessScreen()),
    );
    if (!mounted) return;
    if (widget.gateMode) {
      Navigator.of(context).pop(true);
    } else {
      await _refresh();
    }
  }

  Future<void> _primary() async {
    if (_verified) {
      if (widget.gateMode) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }
    if (!_selfie) {
      await _runSelfie();
      return;
    }
    if (!_digi) {
      await _runDigilocker();
      return;
    }
    await _finishIfVerified();
  }

  @override
  Widget build(BuildContext context) {
    final child = _loading
        ? const Center(
            child: CircularProgressIndicator(color: NytoColors.ctaSoft),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            children: [
              Text(
                _statusTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _statusSubtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.45,
                  color: NytoColors.cream.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 28),
              _StatusBadge(verified: _verified, almost: _selfie || _digi),
              const SizedBox(height: 22),
              _VerifyStepTile(
                number: '1',
                title: 'Live selfie',
                subtitle: 'Quick face check for table safety',
                done: _selfie,
                enabled: true,
                onTap: _runSelfie,
              ),
              const SizedBox(height: 12),
              _VerifyStepTile(
                number: '2',
                title: 'DigiLocker',
                subtitle: 'Government-backed ID — we don’t store your numbers',
                done: _digi,
                enabled: _selfie || _digi,
                lockedHint: 'Finish selfie first',
                onTap: _selfie || _digi ? _runDigilocker : null,
              ),
              const SizedBox(height: 20),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Both steps are required before you can reserve a table. DigiLocker works in the browser — you don’t need the DigiLocker app installed.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.45,
                    color: NytoColors.cream.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          );

    if (widget.gateMode) {
      return OnboardingScaffold(
        step: 1,
        totalSteps: 1,
        showProgress: false,
        footer: NytoPrimaryButton(
          label: _verified
              ? 'Continue to booking'
              : (!_selfie
                  ? 'Start with selfie'
                  : (!_digi ? 'Continue to DigiLocker' : 'Finish')),
          onPressed: _primary,
        ),
        child: child,
      );
    }

    return SettingsPageScaffold(
      title: 'Verify identity',
      footer: NytoPrimaryButton(
        label: _verified
            ? 'Done'
            : (!_selfie
                ? 'Start with selfie'
                : (!_digi ? 'Continue to DigiLocker' : 'Finish')),
        onPressed: _primary,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.verified, required this.almost});

  final bool verified;
  final bool almost;

  @override
  Widget build(BuildContext context) {
    final label = verified
        ? 'Verified'
        : almost
            ? 'Almost there — finish verification'
            : 'Not verified';
    final color = verified
        ? NytoColors.ctaSoft
        : almost
            ? NytoColors.orange
            : NytoColors.cream.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified_rounded
                : Icons.shield_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyStepTile extends StatelessWidget {
  const _VerifyStepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.enabled,
    required this.onTap,
    this.lockedHint,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool done;
  final bool enabled;
  final VoidCallback? onTap;
  final String? lockedHint;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: NytoGlass.panel(
            selected: done,
            borderRadius: 18,
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: done
                        ? const LinearGradient(
                            colors: [NytoColors.ctaSoft, NytoColors.cta],
                          )
                        : null,
                    color: done
                        ? null
                        : NytoColors.cream.withValues(alpha: 0.08),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22)
                      : Text(
                          number,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: NytoColors.cream,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        done
                            ? 'Done'
                            : (!enabled && lockedHint != null
                                ? lockedHint!
                                : subtitle),
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: done
                              ? NytoColors.ctaSoft
                              : NytoColors.cream.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: NytoColors.cream.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
