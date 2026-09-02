import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_auth/smart_auth.dart';

/// Android SMS code retrieval and phone-number hints.
///
/// Uses Google Play Services APIs only:
///  * SMS User Consent — a system dialog shows the single matching message and
///    the code is handed over on approval. No SMS permission, no inbox access.
///  * Phone Number Hint — the OS offers numbers already on the device.
///
/// On iOS both are no-ops: the keyboard's one-time-code strip handles OTP fill
/// through `autofillHints`, which is the platform-supported mechanism there.
class OtpAutofill {
  OtpAutofill._();

  static final _smartAuth = SmartAuth.instance;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Waits for an incoming code. Resolves to null if unsupported, dismissed,
  /// or no code could be extracted.
  ///
  /// Must be started *before* the SMS is requested, or the message can arrive
  /// while nothing is listening.
  static Future<String?> awaitCode() async {
    if (!isSupported) return null;
    try {
      final result = await _smartAuth.getSmsWithUserConsentApi();
      if (!result.hasData) return null;
      final code = result.requireData.code;
      if (code == null || code.isEmpty) return null;
      return code;
    } catch (_) {
      return null;
    }
  }

  /// Stops an in-flight listener, e.g. when the user navigates away.
  static Future<void> cancel() async {
    if (!isSupported) return;
    try {
      await _smartAuth.removeUserConsentApiListener();
    } catch (_) {}
  }

  /// Asks the OS to suggest a phone number from the device.
  ///
  /// This is the platform credential picker — it never touches contacts and
  /// requires no permission.
  static Future<String?> requestPhoneNumberHint() async {
    if (!isSupported) return null;
    try {
      final result = await _smartAuth.requestPhoneNumberHint();
      if (!result.hasData) return null;
      final number = result.requireData;
      return number.isEmpty ? null : number;
    } catch (_) {
      return null;
    }
  }
}
