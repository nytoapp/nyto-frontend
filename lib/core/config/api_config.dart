class ApiConfig {
  /// Android emulator → host machine. For Windows desktop / iOS sim use localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
