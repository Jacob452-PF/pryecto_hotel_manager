import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Comprueba el estado de la conexión.
class ServicioConexion extends ChangeNotifier {
  ServicioConexion._() {
    verificar();
    _reloj = Timer.periodic(const Duration(seconds: 12), (_) => verificar());
  }

  static final ServicioConexion instancia = ServicioConexion._();
  Timer? _reloj;
  bool _sinConexion = false;
  bool _verificando = false;
  bool get sinConexion => _sinConexion;
  bool get verificando => _verificando;

  Future<void> verificar() async {
    if (_verificando) return;
    _verificando = true;
    notifyListeners();
    final disponible = await servidorDisponible();
    final cambio = _sinConexion != !disponible;
    _sinConexion = !disponible;
    _verificando = false;
    if (cambio || _sinConexion) notifyListeners();
  }

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
          .timeout(const Duration(seconds: 6));
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
