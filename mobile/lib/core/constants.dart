import 'dart:io' show Platform;

class ApiConfig {
  /// En emulador Android, `10.0.2.2` apunta al host.
  /// En iOS Simulator, `localhost` funciona directo.
  /// En dispositivo físico, pon la IP de tu máquina en la red local.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  static const Duration timeout = Duration(seconds: 15);
}