import 'package:flutter/foundation.dart';
import 'package:nyto_app/core/api/api_client.dart';

/// JWT from email OTP, or a debug token when Google mock / offline sign-in.
class NytoSession {
  NytoSession._();

  static const _debugToken = 'debug-session';

  static Future<bool> hasSession() async {
    final token = await apiClient.getToken();
    if (token == null || token.isEmpty) return false;
    if (token == _debugToken) return kDebugMode;

    try {
      await apiClient
          .get('/auth/me', auth: true)
          .timeout(const Duration(seconds: 5));
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await apiClient.clearToken();
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Google mock / unreachable API in debug. Skips if a real JWT is already saved.
  static Future<void> markSignedIn() async {
    final token = await apiClient.getToken();
    if (token != null && token.isNotEmpty) return;
    if (!kDebugMode) return;
    await apiClient.saveToken(_debugToken);
  }

  static Future<void> signOut() async {
    await apiClient.clearToken();
  }
}
