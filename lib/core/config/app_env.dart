import 'package:flutter/foundation.dart';

/// Build-time configuration. No secrets live here — only public client IDs.
class AppEnv {
  AppEnv._();

  /// Allow checkout to continue when the API is down.
  static bool get allowDemoCheckout => kDebugMode;

  /// Web OAuth client ID from Google Cloud. Required to get an ID token on
  /// Android.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '76893822257-btilavf1ovqbou8cfakabah9gnjpi3cm.apps.googleusercontent.com',
  );
}
