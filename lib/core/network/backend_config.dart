import 'dart:io';

class BackendConfig {
  const BackendConfig._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }
}
