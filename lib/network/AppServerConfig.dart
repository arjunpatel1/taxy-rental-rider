import 'package:flutter/foundation.dart';

class AppServerConfig {
  static String get baseUrl => kReleaseMode
      ? 'https://staxi.co.in'
      : const String.fromEnvironment('STAXI_API_BASE_URL', defaultValue: 'https://staxi.co.in');
}
