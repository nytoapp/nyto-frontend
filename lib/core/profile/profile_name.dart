import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First name shown on Profile. "Guest" is a signup placeholder, not a name.
class ProfileName {
  ProfileName._();

  static const _key = 'nyto_profile_first_name';

  static bool isPlaceholder(String? raw) {
    final name = raw?.trim() ?? '';
    return name.isEmpty || name.toLowerCase() == 'guest';
  }

  static String? real(String? raw) {
    final name = raw?.trim() ?? '';
    if (isPlaceholder(name)) return null;
    return name;
  }

  static Future<String?> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return real(prefs.getString(_key));
  }

  static Future<void> saveLocal(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name.trim());
  }

  /// Writes the name locally first, then to the account, so Profile can show it
  /// even if the request is retried.
  static Future<String> save(String raw) async {
    final name = raw.trim();
    if (name.length < 2) {
      throw StateError('First name must be at least 2 letters');
    }
    await saveLocal(name);
    final json = await authApi.updateMe({'firstName': name});
    final user = json['user'];
    if (user is Map) {
      final saved = real(user['firstName'] as String?);
      if (saved != null) {
        await saveLocal(saved);
        return saved;
      }
    }
    return name;
  }
}
