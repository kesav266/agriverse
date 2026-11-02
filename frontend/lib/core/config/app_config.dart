/// Environment-specific application configuration for AgriVerse AI.
class AppConfig {
  /// Base API URL configured for local FastAPI server.
  /// Standard Android Emulator loopback is 10.0.2.2, desktop/web is localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String appName = 'AgriVerse AI';
  static const String appVersion = '1.0.0';
  static const int requestTimeoutSeconds = 30;
}
