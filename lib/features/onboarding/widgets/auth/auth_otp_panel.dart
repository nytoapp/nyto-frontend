import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_social_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';
import 'package:nyto_app/features/onboarding/widgets/otp_pin_field.dart';

/// Dedicated OTP screen after Continue on the phone field.
class AuthOtpPanel extends StatefulWidget {
  const AuthOtpPanel({
    super.key,
    required this.state,
    required this.code,
    required this.phoneDisplay,
    required this.onChanged,
    required this.onResend,
    required this.onEditNumber,
  });

  final AuthFlowState state;
  final String code;
  final String phoneDisplay;
  final ValueChanged<String> onChanged;
  final VoidCallback onResend;
  final VoidCallback onEditNumber;

  @override
  State<AuthOtpPanel> createState() => _AuthOtpPanelState();
}

class _AuthOtpPanelState extends State<AuthOtpPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant AuthOtpPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final destination = state.maskedDestination ?? widget.phoneDisplay;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: inset + AuthTokens.space8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthEditorialHeader(
            eyebrow: 'Verify',
            title: 'Enter your code',
            subtitle: 'We texted a 6-digit code to $destination.',
          ),
          AuthBackLink(
            label: '← Change number',
            onTap: widget.onEditNumber,
          ),
          const SizedBox(height: AuthTokens.space12),
          Text(
            widget.phoneDisplay,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NytoColors.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AuthTokens.space20),
          OtpPinField(
            controller: _controller,
            onChanged: widget.onChanged,
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
          if (state.error != null) ...[
            const SizedBox(height: AuthTokens.space16),
            AuthErrorBanner(message: state.error!),
          ],
        ],
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
