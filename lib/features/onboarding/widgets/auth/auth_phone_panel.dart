import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/config/app_env.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_social_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';
import 'package:nyto_app/features/onboarding/widgets/otp_pin_field.dart';

class AuthPhonePanel extends StatelessWidget {
  const AuthPhonePanel({
    super.key,
    required this.state,
    required this.phone,
    required this.otp,
    required this.country,
    required this.devOtpHint,
    required this.onPickCountry,
    required this.onChanged,
    required this.onBack,
    required this.onEditPhone,
  });

  final AuthFlowState state;
  final TextEditingController phone;
  final TextEditingController otp;
  final CountryDial country;
  final String? devOtpHint;
  final VoidCallback onPickCountry;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final VoidCallback onEditPhone;

  @override
  Widget build(BuildContext context) {
    final otpSent = state.phoneOtpSent;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: inset + AuthTokens.space8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthEditorialHeader(
            eyebrow: otpSent ? 'Verify' : 'Phone',
            title: otpSent ? 'Enter your code' : 'Your number',
            subtitle: otpSent
                ? 'We texted a 6-digit code to ${country.dial} ${phone.text.trim()}.'
                : 'We’ll text a one-time code. Anywhere works — pick your country.',
          ),
          AuthBackLink(label: '← Other sign-in options', onTap: onBack),
          const SizedBox(height: AuthTokens.space20),
          if (!otpSent) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CountryChip(country: country, onTap: onPickCountry),
                const SizedBox(width: AuthTokens.space12),
                Expanded(
                  child: _PhoneField(
                    controller: phone,
                    maxLen: country.maxLen,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuthTokens.space12),
            Text(
              '${country.name} · ${country.minLen}–${country.maxLen} digits',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: NytoColors.cream.withValues(alpha: 0.38),
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onEditPhone,
                child: Text(
                  'Change number',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.ctaSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AuthTokens.space8),
            OtpPinField(controller: otp, onChanged: (_) => onChanged()),
            if (AppEnv.allowDevOtp && (devOtpHint?.isNotEmpty ?? false)) ...[
              const SizedBox(height: AuthTokens.space12),
              Text(
                'Dev OTP: $devOtpHint',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: NytoColors.cream.withValues(alpha: 0.38),
                ),
              ),
            ],
          ],
          if (state.error != null) ...[
            const SizedBox(height: AuthTokens.space16),
            AuthErrorBanner(message: state.error!),
          ],
        ],
      ),
    );
  }
}

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

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.country, required this.onTap});

  final CountryDial country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuthTokens.radiusLg),
        child: Ink(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AuthTokens.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuthTokens.radiusLg),
            color: AuthTokens.surfaceElevated.withValues(alpha: 0.7),
            border: Border.all(color: AuthTokens.surfaceBorder),
          ),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                country.dial,
                style: GoogleFonts.dmSans(
                  color: NytoColors.cream,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.maxLen,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int maxLen;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      onChanged: (_) => onChanged(),
      style: GoogleFonts.dmSans(
        color: NytoColors.cream,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: NytoColors.ctaSoft,
      decoration: InputDecoration(
        labelText: 'Number',
        labelStyle: GoogleFonts.dmSans(
          color: NytoColors.cream.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: AuthTokens.surfaceElevated.withValues(alpha: 0.7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTokens.radiusLg),
          borderSide: BorderSide(color: AuthTokens.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTokens.radiusLg),
          borderSide: BorderSide(
            color: NytoColors.ctaSoft.withValues(alpha: 0.75),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
