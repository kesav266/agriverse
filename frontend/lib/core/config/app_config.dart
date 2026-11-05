import 'package:flutter/foundation.dart';

/// Environment-specific application configuration for AgriVerse AI.
class AppConfig {
  static const String _configuredUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Base API URL configured for local FastAPI server.
  /// Standard Android Emulator loopback is 10.0.2.2, desktop/web is localhost.
  static String get apiBaseUrl {
    if (_configuredUrl.isNotEmpty) {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          _configuredUrl.contains('localhost')) {
        return _configuredUrl.replaceFirst('localhost', '10.0.2.2');
      }
      return _configuredUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static const String appName = 'AgriVerse AI';
  static const String appVersion = '1.0.0';
  static const int requestTimeoutSeconds = 30;
}
