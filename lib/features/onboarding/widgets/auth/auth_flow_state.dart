/// Deterministic auth UI state — no contradictory loading flags.
enum AuthView { choice, phone, confirm }

enum AuthProviderKind { phone, google, apple, instagram }

enum AuthBusy { none, phoneSend, phoneVerify, google, apple, instagram }

class AuthFlowState {
  const AuthFlowState({
    this.view = AuthView.choice,
    this.busy = AuthBusy.none,
    this.phoneOtpSent = false,
    this.error,
    this.confirmProvider,
    this.confirmLabel,
  });

  final AuthView view;
  final AuthBusy busy;
  final bool phoneOtpSent;
  final String? error;
  final String? confirmProvider;
  final String? confirmLabel;

  bool get isBusy => busy != AuthBusy.none;

  bool get canInteract => !isBusy;

  AuthFlowState copyWith({
    AuthView? view,
    AuthBusy? busy,
    bool? phoneOtpSent,
    String? error,
    bool clearError = false,
    String? confirmProvider,
    String? confirmLabel,
    bool clearConfirm = false,
  }) {
    return AuthFlowState(
      view: view ?? this.view,
      busy: busy ?? this.busy,
      phoneOtpSent: phoneOtpSent ?? this.phoneOtpSent,
      error: clearError ? null : (error ?? this.error),
      confirmProvider:
          clearConfirm ? null : (confirmProvider ?? this.confirmProvider),
      confirmLabel: clearConfirm ? null : (confirmLabel ?? this.confirmLabel),
    );
  }

  static const initial = AuthFlowState();
}

String friendlyAuthError(Object? err, {String? fallback}) {
  if (err is Exception) {
    final msg = err.toString().replaceFirst('Exception: ', '').trim();
    if (msg.isNotEmpty && !msg.contains('SocketException')) return msg;
  }
  return fallback ?? 'Something went wrong. Check your connection and try again.';
}
