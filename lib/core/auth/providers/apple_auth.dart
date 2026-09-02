import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';

/// Sign in with Apple. Returns the identity token for server-side verification.
class NytoAppleAuth {
  NytoAppleAuth._();

  static Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Throws [AuthFailure]; kind `cancelled` when the sheet is dismissed.
  static Future<String> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthFailure(
          AuthFailureKind.providerRejected,
          'Apple did not return a valid login. Try again.',
        );
      }
      return idToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw switch (e.code) {
        AuthorizationErrorCode.canceled => AuthFailure.cancelled,
        AuthorizationErrorCode.notInteractive ||
        AuthorizationErrorCode.notHandled => const AuthFailure(
          AuthFailureKind.providerUnavailable,
          'Apple sign-in is unavailable right now.',
        ),
        _ => const AuthFailure(
          AuthFailureKind.providerRejected,
          'Apple sign-in failed. Try again.',
        ),
      };
    } on SignInWithAppleNotSupportedException {
      throw const AuthFailure(
        AuthFailureKind.providerUnavailable,
        'Apple sign-in is not supported on this device.',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        AuthFailureKind.providerRejected,
        'Apple sign-in failed. Try again.',
      );
    }
  }
}
