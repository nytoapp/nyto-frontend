class ApiConfig {
  /// Use with: `adb reverse tcp:3000 tcp:3000`
  /// Emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
  /// Same Wi‑Fi (no USB reverse): `--dart-define=API_BASE_URL=http://192.168.29.97:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
}
