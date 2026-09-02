import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_social_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';
import 'package:nyto_app/features/onboarding/widgets/otp_pin_field.dart';

/// One phone surface: number entry morphs into OTP on the same screen
/// (Zomato-style), instead of pushing a second full page.
class AuthPhonePanel extends StatefulWidget {
  const AuthPhonePanel({
    super.key,
    required this.state,
    required this.value,
    required this.country,
    required this.hint,
    this.validationError,
    required this.code,
    required this.onPickCountry,
    required this.onPhoneChanged,
    required this.onCodeChanged,
    required this.onSendCode,
    required this.onResend,
    required this.onEditNumber,
    required this.onBackToChoice,
  });

  final AuthFlowState state;
  final String value;
  final CountryDial country;
  final String hint;
  final String? validationError;
  final String code;
  final VoidCallback onPickCountry;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onSendCode;
  final VoidCallback onResend;
  final VoidCallback onEditNumber;
  final VoidCallback onBackToChoice;

  bool get _otpMode => state.stage == AuthStage.otpVerify;

  @override
  State<AuthPhonePanel> createState() => _AuthPhonePanelState();
}

class _AuthPhonePanelState extends State<AuthPhonePanel> {
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.value);
    _otpController = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant AuthPhonePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
    if (widget.code != _otpController.text) {
      _otpController.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final otp = widget._otpMode;
    final destination = widget.state.maskedDestination ??
        '${widget.country.dial} ${widget.value}'.trim();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: inset + AuthTokens.space8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shared chrome — only the copy updates, so it feels like one sheet.
          AuthEditorialHeader(
            eyebrow: otp ? 'Verify' : 'Phone',
            title: otp ? 'Enter your code' : 'Your number',
            subtitle: otp
                ? 'We texted a 6-digit code to $destination.'
                : 'We’ll text a one-time code. Anywhere works — pick your country.',
          ),
          AuthBackLink(
            label: otp ? '← Change number' : '← Other sign-in options',
            onTap: otp ? widget.onEditNumber : widget.onBackToChoice,
          ),
          const SizedBox(height: AuthTokens.space20),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: otp ? _buildOtpBody() : _buildPhoneBody(),
            ),
          ),
          if (widget.state.error != null ||
              (!otp && widget.validationError != null)) ...[
            const SizedBox(height: AuthTokens.space16),
            AuthErrorBanner(
              message: widget.state.error ?? widget.validationError!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneBody() {
    return KeyedSubtree(
      key: const ValueKey('phone-body'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CountryChip(
                  country: widget.country,
                  onTap: widget.onPickCountry,
                ),
                const SizedBox(width: AuthTokens.space12),
                Expanded(
                  child: _PhoneField(
                    controller: _phoneController,
                    maxLen: widget.country.maxLen,
                    onChanged: widget.onPhoneChanged,
                    onSubmit: widget.onSendCode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuthTokens.space12),
          Text(
            widget.hint,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: NytoColors.cream.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBody() {
    final state = widget.state;
    return KeyedSubtree(
      key: const ValueKey('otp-body'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact reminder of which number is being verified.
          Text(
            '${widget.country.dial} ${widget.value}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NytoColors.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AuthTokens.space16),
          OtpPinField(
            controller: _otpController,
            onChanged: widget.onCodeChanged,
          ),
          const SizedBox(height: AuthTokens.space16),
          _ResendRow(
            canResend: state.canResend,
            countdown: state.resendCountdown,
            isResending: state.busy == AuthBusy.resendingCode,
            onResend: widget.onResend,
          ),
          if (state.autofillActive && widget.code.isEmpty) ...[
            const SizedBox(height: AuthTokens.space12),
            Text(
              'Waiting for the code — we’ll fill it in automatically.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: NytoColors.cream.withValues(alpha: 0.38),
              ),
            ),
          ],
        ],
      ),
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
    required this.onSubmit,
  });

  final TextEditingController controller;
  final int maxLen;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      onChanged: onChanged,
      onSubmitted: (_) => onSubmit?.call(),
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

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.canResend,
    required this.countdown,
    required this.isResending,
    required this.onResend,
  });

  final bool canResend;
  final Duration countdown;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (isResending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation(
                NytoColors.cream.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: AuthTokens.space8),
          Text(
            'Sending a new code…',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    if (!canResend && countdown > Duration.zero) {
      return Center(
        child: Text(
          'Resend code in ${countdown.inSeconds}s',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: NytoColors.cream.withValues(alpha: 0.38),
          ),
        ),
      );
    }

    return Center(
      child: TextButton(
        onPressed: canResend ? onResend : null,
        child: Text(
          'Resend code',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: canResend
                ? NytoColors.ctaSoft
                : NytoColors.cream.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
