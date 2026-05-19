import '../manage_imports.dart';

class AppServerConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return ''; // Don't add slash at the end of the url
    } else if (kProfileMode) {
      return ''; // Don't add slash at the end of the url
    } else {
      return ''; // Don't add slash at the end of the url
    }
  }
}
