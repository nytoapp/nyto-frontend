import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthCancelled implements Exception {}

class AppleAuthException implements Exception {
  AppleAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppleAuthResult {
  AppleAuthResult({
    required this.idToken,
    required this.userIdentifier,
    this.email,
    this.givenName,
  });

  final String idToken;
  final String userIdentifier;
  final String? email;
  final String? givenName;
}

/// Opens Sign in with Apple (Face ID / Touch ID / Apple ID password).
class NytoAppleAuth {
  NytoAppleAuth._();

  static Future<bool> get isAvailable => SignInWithApple.isAvailable();

  static Future<AppleAuthResult?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw AppleAuthException(
          'Apple did not return a token. Enable Sign in with Apple for com.nyto.nytoApp.',
        );
      }

      final given = credential.givenName?.trim();
      final family = credential.familyName?.trim();
      final fullName = [given, family].where((s) => s != null && s.isNotEmpty).join(' ');

      return AppleAuthResult(
        idToken: idToken,
        userIdentifier: credential.userIdentifier ?? '',
        email: credential.email?.trim().toLowerCase(),
        givenName: given ?? (fullName.isNotEmpty ? fullName.split(' ').first : null),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AppleAuthException(e.message);
    } on AppleAuthException {
      rethrow;
    } catch (_) {
      throw AppleAuthException('Apple Sign-In failed. Try again.');
    }
  }
}
