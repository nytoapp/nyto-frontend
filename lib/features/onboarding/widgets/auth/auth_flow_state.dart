/// Which panel the auth flow is showing.
enum AuthStage { choice, phoneInput, otpVerify, confirm }

enum AuthProviderKind { phone, google, apple, facebook }

/// Work the *app* is doing. Exactly one at a time, so no two loaders can
/// contradict each other.
///
/// Deliberately absent: any state for "provider UI is open". While an external
/// sheet is up the app owns no work, so it must not render a loader — see
/// [AuthFlowState.handoffProvider].
enum AuthBusy {
  none,
  sendingCode,
  resendingCode,
  verifyingCode,
  exchangingCredential,
}

class AuthFlowState {
  const AuthFlowState({
    this.stage = AuthStage.choice,
    this.busy = AuthBusy.none,
    this.handoffProvider,
    this.exchangingProvider,
    this.error,
    this.confirmProvider,
    this.confirmLabel,
    this.maskedDestination,
    this.resendAvailableAt,
    this.autofillActive = false,
  });

  final AuthStage stage;
  final AuthBusy busy;

  /// Set while an external provider sheet is open. The UI stays visually idle
  /// and simply ignores taps — the provider owns the screen at this point.
  final AuthProviderKind? handoffProvider;

  /// Which provider's credential is being exchanged with our backend. This is
  /// real app work, so the matching button *does* show a loader.
  final AuthProviderKind? exchangingProvider;

  final String? error;
  final String? confirmProvider;
  final String? confirmLabel;

  /// `+9198•••••210` — shown on the OTP panel.
  final String? maskedDestination;

  /// When resend becomes available again. Null once it already is.
  final DateTime? resendAvailableAt;

  /// True while the OS is listening for the SMS code.
  final bool autofillActive;

  /// A provider sheet is open, or the app is working. Either way, ignore input.
  bool get isLocked => busy != AuthBusy.none || handoffProvider != null;

  /// Whether a spinner belongs on screen. False during provider handoff.
  bool get showsLoader => busy != AuthBusy.none;

  bool get canInteract => !isLocked;

  bool get canResend {
    if (isLocked) return false;
    final at = resendAvailableAt;
    return at == null || !at.isAfter(DateTime.now());
  }

  Duration get resendCountdown {
    final at = resendAvailableAt;
    if (at == null) return Duration.zero;
    final remaining = at.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  AuthFlowState copyWith({
    AuthStage? stage,
    AuthBusy? busy,
    AuthProviderKind? handoffProvider,
    bool clearHandoff = false,
    AuthProviderKind? exchangingProvider,
    bool clearExchanging = false,
    String? error,
    bool clearError = false,
    String? confirmProvider,
    String? confirmLabel,
    bool clearConfirm = false,
    String? maskedDestination,
    DateTime? resendAvailableAt,
    bool clearResend = false,
    bool? autofillActive,
  }) {
    return AuthFlowState(
      stage: stage ?? this.stage,
      busy: busy ?? this.busy,
      handoffProvider: clearHandoff
          ? null
          : (handoffProvider ?? this.handoffProvider),
      exchangingProvider: clearExchanging
          ? null
          : (exchangingProvider ?? this.exchangingProvider),
      error: clearError ? null : (error ?? this.error),
      confirmProvider: clearConfirm
          ? null
          : (confirmProvider ?? this.confirmProvider),
      confirmLabel: clearConfirm ? null : (confirmLabel ?? this.confirmLabel),
      maskedDestination: maskedDestination ?? this.maskedDestination,
      resendAvailableAt: clearResend
          ? null
          : (resendAvailableAt ?? this.resendAvailableAt),
      autofillActive: autofillActive ?? this.autofillActive,
    );
  }

  static const initial = AuthFlowState();
}
