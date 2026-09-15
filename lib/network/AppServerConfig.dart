import '../manage_imports.dart';

class AppServerConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://staxi.co.in'; // Don't add slash at the end of the url
    } else if (kProfileMode) {
      return 'https://staxi.co.in'; // Don't add slash at the end of the url
    } else {
      return 'https://staxi.co.in'; // Don't add slash at the end of the url
    }
  }
}
