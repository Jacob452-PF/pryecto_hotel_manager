import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';

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

  /// Comprueba el API usando una ruta protegida que no requiere credenciales.
  /// Un 401/403 también confirma que Laravel está respondiendo.
  static Future<bool> servidorDisponible() async {
    try {
      final response = await _consultarApi();
      return response != null && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response?> _consultarApi() async {
    try {
      final base = kApiBase.replaceFirst(RegExp(r'/+$'), '');
      return await http
          .get(
            Uri.parse('$base/me'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
