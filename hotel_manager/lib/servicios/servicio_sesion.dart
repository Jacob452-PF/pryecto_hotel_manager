import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/usuario.dart';

/// Guarda quién tiene la sesión abierta y desde cuándo.
/// Cuando exista la API, el login llenará estos datos con la respuesta del servidor.
class ServicioSesion extends ChangeNotifier {
  ServicioSesion._();

  static final ServicioSesion instancia = ServicioSesion._();
  static const _claveUsuario = 'sesion_usuario_guardado';
  static const _claveCorreo = 'correo_recordado';

  Usuario? _usuario;
  DateTime? _inicioSesion;

  Usuario? get usuario => _usuario;
  DateTime? get inicioSesion => _inicioSesion;

  void iniciarSesion(Usuario usuario) {
    _usuario = usuario;
    _inicioSesion = DateTime.now();
    notifyListeners();
  }

  Future<void> guardarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_claveUsuario, [
      usuario.id,
      usuario.nombre,
      usuario.username,
      usuario.rol.name,
      usuario.cargo,
    ]);
  }

  Future<Usuario?> usuarioGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final datos = prefs.getStringList(_claveUsuario);
    if (datos == null || datos.length < 5) return null;
    final rol = RolUsuario.values.where((r) => r.name == datos[3]).firstOrNull;
    if (rol == null) return null;
    return Usuario(
      id: datos[0],
      nombre: datos[1],
      username: datos[2],
      rol: rol,
      cargo: datos[4],
    );
  }

  Future<void> recordarCorreo(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveCorreo, correo.trim());
  }

  Future<String?> leerCorreoRecordado() async =>
      (await SharedPreferences.getInstance()).getString(_claveCorreo);

  Future<void> cerrarSesion() async {
    _usuario = null;
    _inicioSesion = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUsuario);
  }
}
