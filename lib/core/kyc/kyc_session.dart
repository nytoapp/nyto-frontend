import 'package:shared_preferences/shared_preferences.dart';

/// Frontend KYC gate until DigiLocker backend is wired.
class KycSession {
  static const _verifiedKey = 'nyto_kyc_verified';
  static const _digilockerKey = 'nyto_digilocker_linked';

  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verifiedKey) ?? false;
  }

  static Future<bool> isDigilockerLinked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_digilockerKey) ?? false;
  }

  static Future<void> markDigilockerLinked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_digilockerKey, true);
  }

  static Future<void> markVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_digilockerKey, true);
    await prefs.setBool(_verifiedKey, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedKey);
    await prefs.remove(_digilockerKey);
  }
}
