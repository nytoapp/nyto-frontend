import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Access + refresh token pair as returned by the API.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  static AuthTokens? fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    if (access is! String || access.isEmpty) return null;
    if (refresh is! String || refresh.isEmpty) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }
}

/// Tokens live in the platform keystore (Android EncryptedSharedPreferences /
/// iOS Keychain), never in SharedPreferences or app-visible files.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Android encrypts with a KeyStore-backed cipher by default.
            aOptions: AndroidOptions(),
            // `first_unlock` keeps the refresh token readable after a
            // reboot-and-unlock, without syncing it to iCloud.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'nyto_access_token';
  static const _refreshKey = 'nyto_refresh_token';

  /// Pre-refresh-token builds kept a long-lived JWT here. Purged on first read.
  static const _legacyPrefsKey = 'nyto_auth_token';

  AuthTokens? _cached;
  bool _loaded = false;

  Future<AuthTokens?> read() async {
    if (_loaded) return _cached;

    // A corrupt or re-keyed keystore must not brick the app — treat it as
    // "no session" and let the user sign in again.
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access != null &&
          access.isNotEmpty &&
          refresh != null &&
          refresh.isNotEmpty) {
        _cached = AuthTokens(accessToken: access, refreshToken: refresh);
      }
    } catch (_) {
      _cached = null;
    }

    await _purgeLegacyToken();
    _loaded = true;
    return _cached;
  }

  Future<void> write(AuthTokens tokens) async {
    _cached = tokens;
    _loaded = true;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
    await _purgeLegacyToken();
  }

  Future<void> _purgeLegacyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_legacyPrefsKey)) {
        await prefs.remove(_legacyPrefsKey);
      }
    } catch (_) {}
  }
}
