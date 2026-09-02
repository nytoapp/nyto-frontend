import 'package:google_sign_in/google_sign_in.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';
import 'package:nyto_app/core/config/app_env.dart';

/// Google Sign-In via the platform account picker.
///
/// Returns only an ID token; the backend verifies it against the configured
/// client IDs, so a token minted for another app is rejected.
class NytoGoogleAuth {
  NytoGoogleAuth._();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final serverClientId = AppEnv.googleWebClientId;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialized = true;
  }

  /// Throws [AuthFailure]; kind `cancelled` when the chooser is dismissed.
  static Future<String> signIn({bool switchAccount = false}) async {
    try {
      await _ensureInitialized();
    } catch (_) {
      throw const AuthFailure(
        AuthFailureKind.notConfigured,
        'Google Sign-In is not set up on this build.',
      );
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthFailure(
        AuthFailureKind.providerUnavailable,
        'Google Sign-In is not available on this device.',
      );
    }

    if (switchAccount) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          AuthFailureKind.notConfigured,
          'Google Sign-In is missing its server client ID.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      throw _describe(e);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        AuthFailureKind.providerRejected,
        'Google Sign-In failed. Try again.',
      );
    }
  }

  static AuthFailure _describe(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return AuthFailure.cancelled;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AuthFailure(
          AuthFailureKind.notConfigured,
          'Google Sign-In is not configured for this app yet.',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthFailure(
          AuthFailureKind.providerUnavailable,
          'Google Sign-In is unavailable right now. Try another method.',
        );
      case GoogleSignInExceptionCode.userMismatch:
        return const AuthFailure(
          AuthFailureKind.providerRejected,
          'That account did not match. Try again.',
        );
      case GoogleSignInExceptionCode.unknownError:
        return const AuthFailure(
          AuthFailureKind.providerRejected,
          'Google Sign-In failed. Try again.',
        );
    }
  }

  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
