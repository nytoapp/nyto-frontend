import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';

/// Facebook Login.
///
/// Meta shut down the Instagram Basic Display API in December 2024, and its
/// replacement (Instagram API with Instagram Login) covers only professional
/// accounts on web. Facebook Login is Meta's supported consumer identity
/// provider, so it is what the Meta button uses.
///
/// The client only obtains an access token; it is verified server-side against
/// the app secret, which never ships in the app.
class NytoFacebookAuth {
  NytoFacebookAuth._();

  /// Returns the access token, or throws [AuthFailure] (kind `cancelled` when
  /// the user dismissed the sheet).
  static Future<String> signIn() async {
    final LoginResult result;
    try {
      result = await FacebookAuth.instance.login(
        // Email is not guaranteed — Facebook accounts can be phone-only — so
        // the backend treats a missing email as "no email to link on".
        permissions: const ['public_profile', 'email'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      );
    } catch (_) {
      throw const AuthFailure(
        AuthFailureKind.providerUnavailable,
        "Couldn't open Facebook. Try again.",
      );
    }

    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken?.tokenString;
        if (token == null || token.isEmpty) {
          throw const AuthFailure(
            AuthFailureKind.providerRejected,
            'Facebook did not return a valid login. Try again.',
          );
        }
        return token;

      case LoginStatus.cancelled:
        throw AuthFailure.cancelled;

      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw const AuthFailure(
          AuthFailureKind.providerRejected,
          'Facebook sign-in failed. Try again.',
        );
    }
  }

  static Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
