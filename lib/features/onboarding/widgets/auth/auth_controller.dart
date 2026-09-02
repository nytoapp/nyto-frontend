import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';
import 'package:nyto_app/core/auth/auth_repository.dart';
import 'package:nyto_app/core/auth/auth_user.dart';
import 'package:nyto_app/core/auth/otp_autofill.dart';
import 'package:nyto_app/core/auth/phone_number.dart';
import 'package:nyto_app/core/auth/providers/apple_auth.dart';
import 'package:nyto_app/core/auth/providers/facebook_auth.dart';
import 'package:nyto_app/core/auth/providers/google_auth.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';

/// Obtains a credential from an external provider. Injected so tests can drive
/// success, cancellation and failure without touching platform channels.
typedef CredentialProvider = Future<String> Function();

/// Google additionally supports re-prompting for a different account.
typedef GoogleCredentialProvider =
    Future<String> Function({bool switchAccount});

/// All authentication behaviour for the auth step.
///
/// The UI reads [state] and calls intents; it never talks to a provider or the
/// API directly. Every async result is stamped with a generation so a late
/// callback from a cancelled or superseded attempt is discarded rather than
/// mutating state.
class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? repository,
    GoogleCredentialProvider? googleCredential,
    CredentialProvider? appleCredential,
    CredentialProvider? facebookCredential,
    Future<String?> Function()? awaitSmsCode,
    Future<void> Function()? cancelSmsListener,
    Future<String?> Function()? phoneNumberHint,
    CountryDial? initialCountry,
    String initialPhone = '',
  }) : _repo = repository ?? authRepository,
       _googleCredential = googleCredential ?? NytoGoogleAuth.signIn,
       _appleCredential = appleCredential ?? NytoAppleAuth.signIn,
       _facebookCredential = facebookCredential ?? NytoFacebookAuth.signIn,
       _awaitSmsCode = awaitSmsCode ?? OtpAutofill.awaitCode,
       _cancelSmsListener = cancelSmsListener ?? OtpAutofill.cancel,
       _phoneNumberHint = phoneNumberHint ?? OtpAutofill.requestPhoneNumberHint,
       _country = initialCountry ?? OnboardingOptions.countries.first {
    _phoneRaw = initialPhone;
  }

  final AuthRepository _repo;
  final GoogleCredentialProvider _googleCredential;
  final CredentialProvider _appleCredential;
  final CredentialProvider _facebookCredential;
  final Future<String?> Function() _awaitSmsCode;
  final Future<void> Function() _cancelSmsListener;
  final Future<String?> Function() _phoneNumberHint;

  AuthFlowState _state = AuthFlowState.initial;
  AuthFlowState get state => _state;

  CountryDial _country;
  CountryDial get country => _country;

  String _phoneRaw = '';
  String get phoneRaw => _phoneRaw;

  String _code = '';
  String get code => _code;

  /// E.164 number the live OTP challenge was issued for.
  String? _challengePhone;

  AuthUser? _user;
  AuthUser? get user => _user;

  /// Bumped by every intent; async work compares against it before applying
  /// results, which is what makes late callbacks harmless.
  int _generation = 0;

  Timer? _countdown;
  bool _disposed = false;

  PhoneInput get phoneInput => PhoneNumbers.validate(_phoneRaw, _country);

  bool get canSubmitPhone => phoneInput.isValid && _state.canInteract;

  bool get isCodeComplete => _code.length == 6;

  bool get canSubmitCode => isCodeComplete && _state.canInteract;

  String get phoneHint => PhoneNumbers.hint(_country);

  // ── Plumbing ────────────────────────────────────────────────────────────

  void _emit(AuthFlowState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  int _begin() => ++_generation;

  void _fail(int generation, Object error) {
    if (!_isCurrent(generation)) return;
    final failure = describeAuthError(error);
    _emit(
      _state.copyWith(
        busy: AuthBusy.none,
        clearHandoff: true,
        clearExchanging: true,
        // A cancellation is not an error: return to idle silently.
        error: failure.isCancellation ? null : failure.message,
        clearError: failure.isCancellation,
      ),
    );
  }

  // ── Navigation intents ──────────────────────────────────────────────────

  void openPhone() {
    if (!_state.canInteract) return;
    _begin();
    _code = '';
    _emit(
      _state.copyWith(
        stage: AuthStage.phoneInput,
        busy: AuthBusy.none,
        clearError: true,
        clearConfirm: true,
        clearHandoff: true,
      ),
    );
    unawaited(_offerPhoneNumberHint());
  }

  /// Back from wherever we are. Deterministic and confined to the auth flow:
  /// OTP returns to phone input, everything else returns to the choice panel.
  /// Returns false when there is nowhere left to go, so the screen can pop.
  bool goBack() {
    if (_state.busy != AuthBusy.none) return true;

    switch (_state.stage) {
      case AuthStage.otpVerify:
        _begin();
        unawaited(_cancelSmsListener());
        _code = '';
        _challengePhone = null;
        _stopCountdown();
        _emit(
          _state.copyWith(
            stage: AuthStage.phoneInput,
            busy: AuthBusy.none,
            clearError: true,
            clearResend: true,
            autofillActive: false,
            clearHandoff: true,
          ),
        );
        return true;

      case AuthStage.phoneInput:
      case AuthStage.confirm:
        resetToChoice();
        return true;

      case AuthStage.choice:
        return false;
    }
  }

  void resetToChoice() {
    _begin();
    unawaited(_cancelSmsListener());
    _stopCountdown();
    _code = '';
    _challengePhone = null;
    _user = null;
    _emit(AuthFlowState.initial);
  }

  void setCountry(CountryDial country) {
    if (country.code == _country.code && country.dial == _country.dial) return;
    _country = country;
    // Re-sanitize: a number valid for the old country may need reformatting.
    _phoneRaw = PhoneNumbers.sanitize(_phoneRaw, country);
    _emit(_state.copyWith(clearError: true));
  }

  void setPhone(String raw) {
    final sanitized = PhoneNumbers.sanitize(raw, _country);
    if (sanitized == _phoneRaw && _state.error == null) return;
    _phoneRaw = sanitized;
    _emit(_state.copyWith(clearError: true));
  }

  void setCode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final next = digits.length > 6 ? digits.substring(0, 6) : digits;
    if (next == _code) return;
    _code = next;
    _emit(_state.copyWith(clearError: true));

    // Auto-submit the moment a full code is present, from typing, pasting or
    // autofill. `verifyCode` is itself guarded against duplicates.
    if (next.length == 6 && _state.canInteract) {
      unawaited(verifyCode());
    }
  }

  Future<void> _offerPhoneNumberHint() async {
    if (_phoneRaw.isNotEmpty) return;
    final generation = _generation;
    final suggestion = await _phoneNumberHint();
    if (!_isCurrent(generation) || suggestion == null) return;
    if (_phoneRaw.isNotEmpty) return;

    final split = PhoneNumbers.splitE164(suggestion);
    if (split != null) {
      _country = split.country;
      _phoneRaw = split.national;
    } else {
      _phoneRaw = PhoneNumbers.sanitize(suggestion, _country);
    }
    _emit(_state.copyWith(clearError: true));
  }

  // ── Phone OTP ───────────────────────────────────────────────────────────

  /// Sends the first code. Repeat taps while a request is in flight are
  /// ignored, so five taps produce one SMS.
  Future<void> sendCode() => _deliverCode(isResend: false);

  Future<void> resendCode() {
    if (!_state.canResend) return Future.value();
    return _deliverCode(isResend: true);
  }

  Future<void> _deliverCode({required bool isResend}) async {
    if (!_state.canInteract) return;

    final input = phoneInput;
    // The button is already disabled, but never trust the UI alone.
    if (!input.isValid) {
      _emit(
        _state.copyWith(error: input.error ?? 'Enter a valid mobile number.'),
      );
      return;
    }

    final generation = _begin();
    final e164 = input.e164;
    _emit(
      _state.copyWith(
        busy: isResend ? AuthBusy.resendingCode : AuthBusy.sendingCode,
        clearError: true,
      ),
    );

    // Start listening before the request, or the SMS can land while nothing
    // is watching for it.
    final autofill = _awaitSmsCode();

    try {
      final challenge = await _repo.requestPhoneCode(e164);
      if (!_isCurrent(generation)) return;

      _challengePhone = e164;
      if (!isResend) _code = '';

      _emit(
        _state.copyWith(
          stage: AuthStage.otpVerify,
          busy: AuthBusy.none,
          clearError: true,
          maskedDestination: challenge.maskedDestination,
          resendAvailableAt: DateTime.now().add(challenge.resendAfter),
          autofillActive: OtpAutofill.isSupported,
        ),
      );
      _startCountdown();
      unawaited(_applyRetrievedCode(generation, autofill));
    } catch (error) {
      // Cooldown is only restarted on a successful send, so a failed resend
      // leaves the previous countdown untouched.
      unawaited(_cancelSmsListener());
      unawaited(autofill.catchError((_) => null));
      _fail(generation, error);
    }
  }

  /// Applies an OS-retrieved code once OTP entry is actually on screen. The
  /// listener starts earlier than this so no message is missed.
  Future<void> _applyRetrievedCode(
    int generation,
    Future<String?> pending,
  ) async {
    final code = await pending;
    if (!_isCurrent(generation) || code == null) return;
    if (_state.stage != AuthStage.otpVerify) return;
    setCode(code);
  }

  /// Verifies the current code. Safe to call from auto-submit and a manual tap
  /// simultaneously — the second call is dropped.
  Future<void> verifyCode() async {
    if (!_state.canInteract) return;
    if (!isCodeComplete) return;

    final e164 = _challengePhone;
    if (e164 == null) {
      _emit(_state.copyWith(error: 'Request a new code to continue.'));
      return;
    }

    final generation = _begin();
    final submitted = _code;
    _emit(_state.copyWith(busy: AuthBusy.verifyingCode, clearError: true));

    try {
      final user = await _repo.verifyPhoneCode(e164: e164, code: submitted);
      if (!_isCurrent(generation)) return;

      unawaited(_cancelSmsListener());
      _stopCountdown();
      _user = user;
      _emit(
        _state.copyWith(
          busy: AuthBusy.none,
          clearError: true,
          autofillActive: false,
        ),
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      // Clear a rejected code so the field is ready for another try.
      _code = '';
      _fail(generation, error);
    }
  }

  // ── Social providers ────────────────────────────────────────────────────

  Future<void> signInWithGoogle({bool switchAccount = false}) {
    return _runProvider(
      AuthProviderKind.google,
      label: 'Google',
      credential: () => _googleCredential(switchAccount: switchAccount),
      exchange: _repo.signInWithGoogle,
    );
  }

  Future<void> signInWithApple() {
    return _runProvider(
      AuthProviderKind.apple,
      label: 'Apple',
      credential: _appleCredential,
      exchange: _repo.signInWithApple,
    );
  }

  Future<void> signInWithFacebook() {
    return _runProvider(
      AuthProviderKind.facebook,
      label: 'Facebook',
      credential: _facebookCredential,
      exchange: _repo.signInWithFacebook,
    );
  }

  /// Shared provider flow.
  ///
  /// The app enters *handoff* before launching the sheet: taps are ignored but
  /// no loader is drawn, because the provider — not the app — owns the screen.
  /// The loader only appears once a credential is being exchanged with the
  /// backend, which is real app work.
  Future<void> _runProvider(
    AuthProviderKind kind, {
    required String label,
    required CredentialProvider credential,
    required Future<AuthUser> Function(String token) exchange,
  }) async {
    if (!_state.canInteract) return;

    final generation = _begin();
    _emit(
      _state.copyWith(
        handoffProvider: kind,
        busy: AuthBusy.none,
        clearError: true,
      ),
    );

    String token;
    try {
      token = await credential();
    } catch (error) {
      _fail(generation, error);
      return;
    }

    // The user may have navigated away while the sheet was open.
    if (!_isCurrent(generation)) return;

    _emit(
      _state.copyWith(
        busy: AuthBusy.exchangingCredential,
        exchangingProvider: kind,
        clearHandoff: true,
      ),
    );

    try {
      final user = await exchange(token);
      if (!_isCurrent(generation)) return;

      _user = user;
      _emit(
        _state.copyWith(
          stage: AuthStage.confirm,
          busy: AuthBusy.none,
          clearExchanging: true,
          clearError: true,
          confirmProvider: label,
          confirmLabel: user.displayLabel,
        ),
      );
    } catch (error) {
      // Provider succeeded but our session did not: drop the provider session
      // so a retry re-prompts instead of silently reusing a stale credential.
      unawaited(_signOutProvider(kind));
      _fail(generation, error);
    }
  }

  Future<void> _signOutProvider(AuthProviderKind kind) async {
    switch (kind) {
      case AuthProviderKind.google:
        await NytoGoogleAuth.signOut();
      case AuthProviderKind.facebook:
        await NytoFacebookAuth.signOut();
      case AuthProviderKind.apple:
      case AuthProviderKind.phone:
        break;
    }
  }

  // ── Countdown ───────────────────────────────────────────────────────────

  void _startCountdown() {
    _stopCountdown();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (_state.resendCountdown == Duration.zero) {
        timer.cancel();
        _countdown = null;
      }
      notifyListeners();
    });
  }

  void _stopCountdown() {
    _countdown?.cancel();
    _countdown = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopCountdown();
    unawaited(_cancelSmsListener());
    super.dispose();
  }
}
