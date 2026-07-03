import '../manage_imports.dart';

class AppServerConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'http://192.168.100.230:8000'; // Don't add slash at the end of the url
    } else if (kProfileMode) {
      return 'http://192.168.100.230:8000'; // Don't add slash at the end of the url
    } else {
      return 'http://192.168.100.230:8000'; // Don't add slash at the end of the url
    }
  }
}
