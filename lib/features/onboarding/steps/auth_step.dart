import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_choice_panel.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_confirm_panel.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_controller.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_otp_panel.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_primary_button.dart';
import 'package:nyto_app/features/onboarding/widgets/country_code_sheet.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Auth hub — Zomato-style phone field on the choice screen, OTP as its own
/// panel, plus Facebook and Google (Apple on iOS).
class AuthStep extends StatefulWidget {
  const AuthStep({super.key, required this.data, required this.onContinue});

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<AuthStep> createState() => _AuthStepState();
}

class _AuthStepState extends State<AuthStep> {
  late final AuthController _auth;
  bool _didAdvance = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(
      initialPhone: widget.data.phone,
      initialCountry: OnboardingOptions.countries.firstWhere(
        (country) => country.dial == widget.data.countryDial,
        orElse: () => OnboardingOptions.countries.first,
      ),
    )..addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});

    final user = _auth.user;
    if (user != null &&
        _auth.state.stage == AuthStage.otpVerify &&
        !_didAdvance) {
      _didAdvance = true;
      _commit(method: 'phone');
      widget.onContinue();
    }
  }

  void _commit({required String method}) {
    final user = _auth.user;
    if (user == null) return;

    widget.data.authMethod = method;
    widget.data.countryDial = _auth.country.dial;
    widget.data.countryCode = _auth.country.code;

    final phone = user.phone ?? _auth.phoneInput.nationalNumber;
    if (phone.isNotEmpty) widget.data.phone = phone;

    final email = user.email;
    if (email != null && email.isNotEmpty) widget.data.email = email;

    switch (method) {
      case 'google':
        widget.data.googleAccount = email ?? user.displayLabel;
      case 'apple':
        widget.data.appleAccount = email ?? user.displayLabel;
      case 'facebook':
        widget.data.facebookAccount = email ?? user.displayLabel;
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryCodeSheet(context, selected: _auth.country);
    if (picked != null && mounted) _auth.setCountry(picked);
  }

  void _continueFromConfirm() {
    if (_didAdvance) return;
    _didAdvance = true;
    final provider = _auth.state.confirmProvider?.toLowerCase() ?? 'google';
    _commit(method: provider);
    widget.onContinue();
  }

  Widget? _buildFooter() {
    final state = _auth.state;

    // Continue for phone lives on the choice panel itself (Zomato-style).
    switch (state.stage) {
      case AuthStage.choice:
      case AuthStage.phoneInput:
        return null;

      case AuthStage.otpVerify:
        final verifying = state.busy == AuthBusy.verifyingCode;
        return AuthFooterButton(
          label: verifying ? 'Verifying…' : 'Continue',
          loading: verifying,
          enabled: _auth.canSubmitCode,
          onPressed: _auth.canSubmitCode ? _auth.verifyCode : null,
        );

      case AuthStage.confirm:
        return AuthFooterButton(
          label: 'Continue',
          enabled: state.canInteract,
          onPressed: state.canInteract ? _continueFromConfirm : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _auth.state;

    return PopScope(
      canPop: state.stage == AuthStage.choice && !state.isLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _auth.goBack();
      },
      child: OnboardingScaffold(
        step: 3,
        totalSteps: OnboardingData.totalSteps,
        resizeForKeyboard: true,
        footer: _buildFooter(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey(state.stage),
            width: double.infinity,
            height: double.infinity,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final state = _auth.state;

    switch (state.stage) {
      case AuthStage.choice:
      case AuthStage.phoneInput:
        return AuthChoicePanel(
          isIos: _isIos,
          state: state,
          phoneValue: _auth.phoneRaw,
          country: _auth.country,
          phoneHint: _auth.phoneHint,
          validationError: _auth.phoneInput.error,
          onPickCountry: _pickCountry,
          onPhoneChanged: _auth.setPhone,
          onPhoneFocused: _auth.requestPhoneNumberHint,
          onContinue: _auth.canSubmitPhone ? _auth.sendCode : null,
          onFacebook: _auth.signInWithFacebook,
          onGoogle: _auth.signInWithGoogle,
          onApple: _auth.signInWithApple,
        );

      case AuthStage.otpVerify:
        return AuthOtpPanel(
          state: state,
          code: _auth.code,
          phoneDisplay: '${_auth.country.dial} ${_auth.phoneRaw}',
          onChanged: _auth.setCode,
          onResend: _auth.resendCode,
          onEditNumber: _auth.goBack,
        );

      case AuthStage.confirm:
        return AuthConfirmPanel(
          provider: state.confirmProvider ?? 'Account',
          label: state.confirmLabel ?? '',
          onBack: _auth.resetToChoice,
          onSwitch: state.confirmProvider == 'Apple'
              ? _auth.signInWithApple
              : state.confirmProvider == 'Facebook'
                  ? _auth.signInWithFacebook
                  : () => _auth.signInWithGoogle(switchAccount: true),
        );
    }
  }
}
