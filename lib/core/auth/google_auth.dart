import 'package:google_sign_in/google_sign_in.dart';
import 'package:nyto_app/core/config/app_env.dart';

class GoogleAuthCancelled implements Exception {}

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoogleAuthResult {
  GoogleAuthResult({
    required this.idToken,
    required this.email,
    required this.displayName,
  });

  final String idToken;
  final String email;
  final String displayName;
}

/// Opens the phone's Google account picker and returns an ID token for NYTO.
class NytoGoogleAuth {
  NytoGoogleAuth._();

  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    final serverClientId = AppEnv.googleWebClientId;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _ready = true;
  }

  static Future<GoogleAuthResult?> signIn({bool switchAccount = false}) async {
    await _ensureReady();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw GoogleAuthException(
        'Google Sign-In is not available on this device.',
      );
    }
    if (switchAccount) {
      await GoogleSignIn.instance.signOut();
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw GoogleAuthException(
          'Google did not return a token. Add your Web client ID as GOOGLE_WEB_CLIENT_ID.',
        );
      }
      return GoogleAuthResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName ?? account.email,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw GoogleAuthException(
          'Google Sign-In is not set up yet. Add the Android SHA-1 and Web client ID in Google Cloud.',
        );
      }
      throw GoogleAuthException(
        e.description ?? 'Google Sign-In failed. Try again.',
      );
    }
  }
}
