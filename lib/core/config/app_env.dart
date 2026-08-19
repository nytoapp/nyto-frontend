import 'package:flutter/foundation.dart';

/// Debug-only shortcuts. Release builds must talk to a real API.
class AppEnv {
  AppEnv._();

  /// Allow checkout to continue when the API is down.
  static bool get allowDemoCheckout => kDebugMode;

  /// Accept the local OTP `000000` without a mail provider.
  static bool get allowDevOtp => kDebugMode;

  static const devOtp = '000000';

  /// Web OAuth client ID from Google Cloud. Required to get an ID token on Android.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '76893822257-btilavf1ovqbou8cfakabah9gnjpi3cm.apps.googleusercontent.com',
  );
}
