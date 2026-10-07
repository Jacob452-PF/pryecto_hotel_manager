import 'package:flutter/foundation.dart';
import '../modelos/usuario.dart';

/// Guarda quién tiene la sesión abierta y desde cuándo.
/// Cuando exista la API, el login llenará estos datos con la respuesta del servidor.
class ServicioSesion extends ChangeNotifier {
  ServicioSesion._();

  static final ServicioSesion instancia = ServicioSesion._();

  Usuario? _usuario;
  DateTime? _inicioSesion;

  Usuario? get usuario => _usuario;
  DateTime? get inicioSesion => _inicioSesion;

  void iniciarSesion(Usuario usuario) {
    _usuario = usuario;
    _inicioSesion = DateTime.now();
    notifyListeners();
  }

  void cerrarSesion() {
    _usuario = null;
    _inicioSesion = null;
    notifyListeners();
  }
} 