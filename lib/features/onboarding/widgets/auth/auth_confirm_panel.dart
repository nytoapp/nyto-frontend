import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';

/// Shown after a social provider signed the user in, so they can confirm which
/// account NYTO will use before continuing.
class AuthConfirmPanel extends StatelessWidget {
  const AuthConfirmPanel({
    super.key,
    required this.provider,
    required this.label,
    required this.onBack,
    required this.onSwitch,
  });

  final String provider;
  final String label;
  final VoidCallback onBack;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == 'Apple';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthEditorialHeader(
          eyebrow: 'Confirmed',
          title: 'You’re almost in',
          subtitle: 'We’ll use this account for your NYTO seat.',
        ),
        const SizedBox(height: AuthTokens.space32),
        Container(
          padding: const EdgeInsets.all(AuthTokens.space20),
          decoration: BoxDecoration(
            color: AuthTokens.surfaceElevated.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AuthTokens.radiusXl),
            border: Border.all(color: AuthTokens.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isApple
                      ? Colors.white
                      : NytoColors.cta.withValues(alpha: 0.18),
                  border: Border.all(
                    color: isApple
                        ? Colors.white.withValues(alpha: 0.2)
                        : NytoColors.cta.withValues(alpha: 0.35),
                  ),
                ),
                child: isApple
                    ? const AppleLogoMark(size: 26, color: Colors.black)
                    : Text(
                        label.isNotEmpty ? label[0].toUpperCase() : '?',
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: NytoColors.cream,
                        ),
                      ),
              ),
              const SizedBox(width: AuthTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AuthTokens.space16),
        TextButton(
          onPressed: onSwitch,
          child: Text(
            'Switch $provider account',
            style: GoogleFonts.dmSans(
              color: NytoColors.ctaSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AuthBackLink(label: 'Other sign-in options', onTap: onBack),
      ],
    );
  }
}
