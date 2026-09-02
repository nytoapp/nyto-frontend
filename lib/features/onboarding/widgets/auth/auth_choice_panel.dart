import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_primary_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_social_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';

/// Zomato-style auth surface: phone field always visible, Continue, then
/// Facebook / Google on the same screen. OTP is a separate stage.
class AuthChoicePanel extends StatefulWidget {
  const AuthChoicePanel({
    super.key,
    required this.isIos,
    required this.state,
    required this.phoneValue,
    required this.country,
    required this.phoneHint,
    this.validationError,
    required this.onPickCountry,
    required this.onPhoneChanged,
    required this.onPhoneFocused,
    required this.onContinue,
    required this.onFacebook,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isIos;
  final AuthFlowState state;
  final String phoneValue;
  final CountryDial country;
  final String phoneHint;
  final String? validationError;
  final VoidCallback onPickCountry;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onPhoneFocused;
  final VoidCallback? onContinue;
  final VoidCallback onFacebook;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  State<AuthChoicePanel> createState() => _AuthChoicePanelState();
}

class _AuthChoicePanelState extends State<AuthChoicePanel> {
  late final TextEditingController _phoneController;
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phoneValue);
    _phoneFocus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant AuthChoicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phoneValue != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: widget.phoneValue,
        selection: TextSelection.collapsed(offset: widget.phoneValue.length),
      );
    }
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocus);
    _phoneFocus.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_phoneFocus.hasFocus) widget.onPhoneFocused();
  }

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.state.canInteract;
    final secondary =
        widget.isIos ? AuthProviderKind.apple : AuthProviderKind.google;
    final exchanging = widget.state.busy == AuthBusy.exchangingCredential
        ? widget.state.exchangingProvider
        : null;
    final sending = widget.state.busy == AuthBusy.sendingCode;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: inset + AuthTokens.space8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthEditorialHeader(
            eyebrow: 'Almost there',
            title: 'Create your seat',
            subtitle: 'One tap in. Phone, Facebook, or your usual sign-in.',
          ),
          const SizedBox(height: AuthTokens.space24),
          AutofillGroup(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CountryChip(
                  country: widget.country,
                  enabled: canInteract && !sending,
                  onTap: widget.onPickCountry,
                ),
                const SizedBox(width: AuthTokens.space12),
                Expanded(
                  child: _PhoneField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    maxLen: widget.country.maxLen,
                    enabled: canInteract && !sending,
                    onChanged: widget.onPhoneChanged,
                    onSubmit: widget.onContinue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuthTokens.space12),
          Text(
            widget.phoneHint,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: NytoColors.cream.withValues(alpha: 0.38),
            ),
          ),
          if (widget.state.error ?? widget.validationError
              case final message?) ...[
            const SizedBox(height: AuthTokens.space16),
            AuthErrorBanner(message: message),
          ],
          const SizedBox(height: AuthTokens.space20),
          AuthPrimaryButton(
            label: sending ? 'Sending code…' : 'Continue',
            loading: sending,
            enabled: canInteract && widget.onContinue != null,
            onPressed: widget.onContinue,
            semanticsLabel: 'Continue with phone',
          ),
          const SizedBox(height: AuthTokens.space24),
          const AuthDivider(),
          const SizedBox(height: AuthTokens.space16),
          Row(
            children: [
              Expanded(
                child: AuthSocialButton(
                  variant: AuthSocialVariant.facebook,
                  loading: exchanging == AuthProviderKind.facebook,
                  enabled: canInteract,
                  onPressed: canInteract ? widget.onFacebook : null,
                ),
              ),
              const SizedBox(width: AuthTokens.space12),
              Expanded(
                child: AuthSocialButton(
                  variant: socialVariant(secondary),
                  loading: exchanging == secondary,
                  enabled: canInteract,
                  onPressed: canInteract
                      ? (widget.isIos ? widget.onApple : widget.onGoogle)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuthTokens.space24),
          const AuthLegalFooter(),
          const SizedBox(height: AuthTokens.space8),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.onTap,
    required this.enabled,
  });

  final CountryDial country;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
    required this.focusNode,
    required this.maxLen,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLen;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
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
        labelText: 'Phone number',
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthTokens.radiusLg),
          borderSide: BorderSide(color: AuthTokens.surfaceBorder),
        ),
      ),
    );
  }
}
