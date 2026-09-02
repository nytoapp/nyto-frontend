import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/auth/auth_repository.dart';
import 'package:nyto_app/core/auth/auth_user.dart';
import 'package:nyto_app/core/kyc/kyc_session.dart';

/// Whether this install has a real, server-backed session.
///
/// There is no debug or offline shortcut: a session exists only when the
/// backend issued tokens for it.
class NytoSession {
  NytoSession._();

  /// True when tokens are present and the backend has not rejected them.
  ///
  /// Being offline is not treated as signed out — the stored refresh token is
  /// still valid, so the user stays in and requests recover once connectivity
  /// returns.
  static Future<bool> hasSession() async {
    if (!await apiClient.hasSession()) return false;

    try {
      return await authRepository.currentUser() != null;
    } on ApiException {
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<AuthUser?> currentUser() async {
    try {
      return await authRepository.currentUser();
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await authRepository.signOut();
    await KycSession.clear();
  }
}
