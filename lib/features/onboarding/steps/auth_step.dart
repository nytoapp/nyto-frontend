import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/auth/apple_auth.dart';
import 'package:nyto_app/core/auth/google_auth.dart';
import 'package:nyto_app/core/config/app_env.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_choice_panel.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_phone_panel.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_primary_button.dart';
import 'package:nyto_app/features/onboarding/widgets/country_code_sheet.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Premium auth hub — phone OTP + Instagram + Google (Android) or Apple (iOS).
class AuthStep extends StatefulWidget {
  const AuthStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<AuthStep> createState() => _AuthStepState();
}

class _AuthStepState extends State<AuthStep> {
  late final TextEditingController _phone;
  late final TextEditingController _otp;
  late CountryDial _country;

  AuthFlowState _state = AuthFlowState.initial;
  String? _devOtpHint;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.data.phone);
    _otp = TextEditingController();
    _country = OnboardingOptions.countries.firstWhere(
      (c) => c.dial == widget.data.countryDial,
      orElse: () => OnboardingOptions.countries.first,
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final local = _phone.text.replaceAll(RegExp(r'\D'), '');
    final dial = _country.dial.replaceAll(RegExp(r'\D'), '');
    return '$dial$local';
  }

  bool get _phoneValid {
    final len = _phone.text.trim().length;
    return len >= _country.minLen && len <= _country.maxLen;
  }

  bool get _otpValid => _otp.text.trim().length == 6;

  void _setState(AuthFlowState next) => setState(() => _state = next);

  void _clearError() {
    if (_state.error != null) {
      _setState(_state.copyWith(clearError: true));
    }
  }

  String _reachError() =>
      'Could not reach NYTO. Is the server running? On a phone, run adb reverse tcp:3000 tcp:3000.';

  void _resetToChoice() {
    _setState(
      AuthFlowState.initial.copyWith(
        clearError: true,
        clearConfirm: true,
      ),
    );
    _devOtpHint = null;
    _otp.clear();
    widget.data.googleAccount = null;
    widget.data.appleAccount = null;
  }

  void _openPhone() {
    if (!_state.canInteract) return;
    _setState(
      _state.copyWith(
        view: AuthView.phone,
        phoneOtpSent: false,
        clearError: true,
      ),
    );
    _otp.clear();
    _devOtpHint = null;
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryCodeSheet(context, selected: _country);
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }

  Future<void> _sendPhoneOtp() async {
    if (!_state.canInteract || !_phoneValid) {
      _setState(_state.copyWith(
        error: 'Enter a valid mobile number.',
      ));
      return;
    }
    _setState(_state.copyWith(
      busy: AuthBusy.phoneSend,
      clearError: true,
    ));
    final phone = _fullPhone;
    try {
      final json = await authApi.requestPhoneOtp(phone);
      if (!mounted) return;
      widget.data.phone = _phone.text.trim();
      widget.data.countryDial = _country.dial;
      widget.data.countryCode = _country.code;
      final hint = json['devOtp'] as String?;
      _devOtpHint = AppEnv.allowDevOtp && hint != null && hint.isNotEmpty
          ? hint
          : null;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        phoneOtpSent: true,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
    } catch (_) {
      if (!mounted) return;
      if (AppEnv.allowDevOtp) {
        widget.data.phone = _phone.text.trim();
        widget.data.countryDial = _country.dial;
        widget.data.countryCode = _country.code;
        _devOtpHint = AppEnv.devOtp;
        _setState(_state.copyWith(
          busy: AuthBusy.none,
          phoneOtpSent: true,
        ));
        return;
      }
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: _reachError(),
      ));
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (!_state.canInteract || !_otpValid) return;
    final code = _otp.text.trim();
    final phone = _fullPhone;
    _setState(_state.copyWith(
      busy: AuthBusy.phoneVerify,
      clearError: true,
    ));
    try {
      await authApi.verifyPhoneOtp(phone: phone, code: code);
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
      return;
    } catch (_) {
      if (AppEnv.allowDevOtp && code == AppEnv.devOtp) {
        await NytoSession.markSignedIn();
      } else {
        if (!mounted) return;
        _setState(_state.copyWith(
          busy: AuthBusy.none,
          error: _reachError(),
        ));
        return;
      }
    }
    if (!mounted) return;
    widget.data.authMethod = 'phone';
    widget.data.phone = _phone.text.trim();
    widget.data.countryDial = _country.dial;
    widget.data.countryCode = _country.code;
    widget.onContinue();
  }

  Future<void> _signInGoogle({bool switchAccount = false}) async {
    if (!_state.canInteract) return;
    _setState(_state.copyWith(
      busy: AuthBusy.google,
      clearError: true,
    ));
    try {
      final google = await NytoGoogleAuth.signIn(switchAccount: switchAccount);
      if (!mounted) return;
      if (google == null) {
        _setState(_state.copyWith(busy: AuthBusy.none));
        return;
      }
      final json = await authApi.googleSignIn(google.idToken);
      if (!mounted) return;
      final user = json['user'];
      final email = user is Map && user['email'] is String
          ? user['email'] as String
          : google.email;
      widget.data.googleAccount = email;
      widget.data.email = email;
      widget.data.authMethod = 'google';
      _setState(_state.copyWith(
        view: AuthView.confirm,
        busy: AuthBusy.none,
        confirmProvider: 'Google',
        confirmLabel: email,
      ));
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
    } catch (_) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: _reachError(),
      ));
    }
  }

  Future<void> _signInApple() async {
    if (!_state.canInteract) return;
    _setState(_state.copyWith(
      busy: AuthBusy.apple,
      clearError: true,
    ));
    try {
      final apple = await NytoAppleAuth.signIn();
      if (!mounted) return;
      if (apple == null) {
        _setState(_state.copyWith(busy: AuthBusy.none));
        return;
      }
      final json = await authApi.appleSignIn(apple.idToken);
      if (!mounted) return;
      final user = json['user'];
      final email = user is Map && user['email'] is String
          ? user['email'] as String
          : apple.email;
      final label = email ?? apple.givenName ?? 'Apple ID';
      widget.data.appleAccount = label;
      if (email != null) widget.data.email = email;
      widget.data.authMethod = 'apple';
      _setState(_state.copyWith(
        view: AuthView.confirm,
        busy: AuthBusy.none,
        confirmProvider: 'Apple',
        confirmLabel: label,
      ));
    } on AppleAuthException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: friendlyAuthError(e, fallback: e.message),
      ));
    } catch (_) {
      if (!mounted) return;
      _setState(_state.copyWith(
        busy: AuthBusy.none,
        error: _reachError(),
      ));
    }
  }

  void _instagramTap() {
    if (!_state.canInteract) return;
    _setState(_state.copyWith(
      busy: AuthBusy.instagram,
      clearError: true,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF141820),
        content: const Text('Instagram login is coming soon.'),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _setState(_state.copyWith(busy: AuthBusy.none));
    });
  }

  void _continueFromConfirm() {
    widget.onContinue();
  }

  Widget? _buildFooter() {
    if (_state.view == AuthView.choice) return null;

    if (_state.view == AuthView.phone) {
      if (!_state.phoneOtpSent) {
        return AuthFooterButton(
          label: _state.busy == AuthBusy.phoneSend ? 'Sending code…' : 'Send code',
          loading: _state.busy == AuthBusy.phoneSend,
          enabled: _phoneValid && _state.busy != AuthBusy.phoneSend,
          onPressed: _phoneValid && _state.busy != AuthBusy.phoneSend
              ? _sendPhoneOtp
              : null,
        );
      }
      return AuthFooterButton(
        label: _state.busy == AuthBusy.phoneVerify ? 'Verifying…' : 'Continue',
        loading: _state.busy == AuthBusy.phoneVerify,
        enabled: _otpValid && _state.busy != AuthBusy.phoneVerify,
        onPressed: _otpValid && _state.busy != AuthBusy.phoneVerify
            ? _verifyPhoneOtp
            : null,
      );
    }

    if (_state.view == AuthView.confirm) {
      return AuthFooterButton(
        label: 'Continue',
        enabled: _state.canInteract,
        onPressed: _state.canInteract ? _continueFromConfirm : null,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 4,
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
          key: ValueKey(_state.view),
          width: double.infinity,
          height: double.infinity,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state.view) {
      case AuthView.choice:
        return AuthChoicePanel(
          isIos: _isIos,
          state: _state,
          onPhone: _openPhone,
          onInstagram: _instagramTap,
          onGoogle: _signInGoogle,
          onApple: _signInApple,
        );
      case AuthView.phone:
        return AuthPhonePanel(
          state: _state,
          phone: _phone,
          otp: _otp,
          country: _country,
          devOtpHint: _devOtpHint,
          onPickCountry: _pickCountry,
          onChanged: _clearError,
          onBack: _resetToChoice,
          onEditPhone: () {
            _setState(_state.copyWith(
              phoneOtpSent: false,
              clearError: true,
            ));
            _otp.clear();
            _devOtpHint = null;
          },
        );
      case AuthView.confirm:
        return AuthConfirmPanel(
          provider: _state.confirmProvider ?? 'Account',
          label: _state.confirmLabel ?? '',
          onBack: _resetToChoice,
          onSwitch: _state.confirmProvider == 'Apple'
              ? _signInApple
              : () => _signInGoogle(switchAccount: true),
        );
    }
  }
}
