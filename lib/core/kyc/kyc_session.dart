import 'package:shared_preferences/shared_preferences.dart';

/// Frontend KYC gate until DigiLocker / selfie APIs are wired.
class KycSession {
  static const _selfieKey = 'nyto_kyc_selfie';
  static const _digilockerKey = 'nyto_digilocker_linked';
  static const _verifiedKey = 'nyto_kyc_verified'; // legacy; derived from both

  static Future<bool> isSelfieDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_selfieKey) ?? false;
  }

  static Future<bool> isDigilockerLinked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_digilockerKey) ?? false;
  }

  /// Fully verified = selfie + DigiLocker.
  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final selfie = prefs.getBool(_selfieKey) ?? false;
    final digi = prefs.getBool(_digilockerKey) ?? false;
    if (selfie && digi) {
      await prefs.setBool(_verifiedKey, true);
      return true;
    }
    // Legacy: older builds set a single verified flag after selfie finish.
    final legacy = prefs.getBool(_verifiedKey) ?? false;
    if (legacy) {
      await prefs.setBool(_selfieKey, true);
      await prefs.setBool(_digilockerKey, true);
      return true;
    }
    return false;
  }

  static Future<void> markSelfieDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_selfieKey, true);
    await _syncVerifiedFlag(prefs);
  }

  static Future<void> markDigilockerLinked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_digilockerKey, true);
    await _syncVerifiedFlag(prefs);
  }

  static Future<void> _syncVerifiedFlag(SharedPreferences prefs) async {
    final selfie = prefs.getBool(_selfieKey) ?? false;
    final digi = prefs.getBool(_digilockerKey) ?? false;
    if (selfie && digi) {
      await prefs.setBool(_verifiedKey, true);
    } else {
      await prefs.setBool(_verifiedKey, false);
    }
  }

  static Future<String> statusLabel() async {
    final verified = await isVerified();
    if (verified) return 'Verified';
    final selfie = await isSelfieDone();
    final digi = await isDigilockerLinked();
    if (selfie || digi) return 'Almost there — finish verification';
    return 'Not verified';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selfieKey);
    await prefs.remove(_digilockerKey);
    await prefs.remove(_verifiedKey);
  }
}
