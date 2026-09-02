import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';
import 'package:nyto_app/core/auth/auth_user.dart';
import 'package:nyto_app/core/auth/token_store.dart';

/// The only place that exchanges credentials for an app session.
///
/// Every sign-in method ends here, so there is exactly one code path that
/// persists tokens and produces an [AuthUser].
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  // ── Phone ───────────────────────────────────────────────────────────────

  /// Asks the server to send an SMS code to an E.164 number.
  Future<OtpChallengeInfo> requestPhoneCode(String e164) {
    return _guard(() async {
      final json = await _api.post(
        '/auth/phone/otp/request',
        body: {'phone': e164},
      );
      return OtpChallengeInfo.fromJson(json, fallbackDestination: e164);
    });
  }

  Future<AuthUser> verifyPhoneCode({
    required String e164,
    required String code,
  }) {
    return _session('/auth/phone/otp/verify', {'phone': e164, 'code': code});
  }

  // ── Email ───────────────────────────────────────────────────────────────

  Future<OtpChallengeInfo> requestEmailCode(String email) {
    return _guard(() async {
      final json = await _api.post(
        '/auth/email/otp/request',
        body: {'email': email},
      );
      return OtpChallengeInfo.fromJson(json, fallbackDestination: email);
    });
  }

  Future<AuthUser> verifyEmailCode({
    required String email,
    required String code,
  }) {
    return _session('/auth/email/otp/verify', {'email': email, 'code': code});
  }

  // ── Social ──────────────────────────────────────────────────────────────

  Future<AuthUser> signInWithGoogle(String idToken) {
    return _session('/auth/google', {'idToken': idToken});
  }

  Future<AuthUser> signInWithApple(String idToken) {
    return _session('/auth/apple', {'idToken': idToken});
  }

  Future<AuthUser> signInWithFacebook(String accessToken) {
    return _session('/auth/facebook', {'accessToken': accessToken});
  }

  // ── Session ─────────────────────────────────────────────────────────────

  /// Resolves the signed-in user, or null when there is no valid session.
  ///
  /// [ApiClient] refreshes transparently, so a null result means the session
  /// is genuinely gone rather than merely stale.
  Future<AuthUser?> currentUser() async {
    if (!await _api.hasSession()) return null;
    try {
      final json = await _api.get('/auth/me', auth: true);
      return AuthUser.fromJson(json['user']);
    } on SessionExpiredException {
      return null;
    } on ApiException catch (e) {
      // Offline or server trouble: the session is not proven invalid, so keep
      // it and let the caller decide. Only a 401/404 means "no user".
      if (e.statusCode == 404) {
        await _api.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final tokens = await _api.currentTokens();
    if (tokens != null) {
      try {
        await _api.post(
          '/auth/logout',
          body: {'refreshToken': tokens.refreshToken},
        );
      } catch (_) {
        // Local sign-out must succeed even if the server is unreachable.
      }
    }
    await _api.clearTokens();
  }

  // ── Internals ───────────────────────────────────────────────────────────

  Future<AuthUser> _session(String path, Map<String, dynamic> body) {
    return _guard(() async {
      final json = await _api.post(path, body: body);

      final tokens = AuthTokens.fromJson(json);
      if (tokens == null) {
        throw const AuthFailure(
          AuthFailureKind.server,
          'Sign-in did not complete. Try again.',
        );
      }

      final user = AuthUser.fromJson(json['user']);
      if (user == null) {
        throw const AuthFailure(
          AuthFailureKind.server,
          'Sign-in did not complete. Try again.',
        );
      }

      // Tokens are only persisted once a real user came back with them, so the
      // app can never believe it is signed in without a server-side session.
      await _api.saveTokens(tokens);
      return user;
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw describeAuthError(error);
    }
  }
}

final authRepository = AuthRepository(apiClient);
