import 'dart:async';
import 'dart:io';

/// Comprueba el estado de la conexión.
class ServicioConexion {
  ServicioConexion._();

  /// Intenta resolver un nombre de internet. Si responde, hay conexión.
  static Future<bool> hayInternet() async {
    try {
      final direcciones = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return direcciones.isNotEmpty && direcciones.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  /// null = todavía no hay servidor configurado.
  /// TODO: cuando exista la API, hacer una petición a un endpoint de prueba
  /// (por ejemplo /api/ping) y devolver true o false.
  static Future<bool?> servidorDisponible() async => null;
}