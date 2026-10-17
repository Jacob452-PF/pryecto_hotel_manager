import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/paletas_tema.dart';

/// Guarda la paleta de colores que eligió el usuario y la recuerda
/// aunque se cierre la app.
class ServicioTema extends ChangeNotifier {
  ServicioTema._();

  static final ServicioTema instancia = ServicioTema._();
  static const _claveColor = 'tema_visual';

  PaletaTema _paleta = PaletasTema.predeterminada;

  PaletaTema get paleta => _paleta;

  /// Se llama una vez al iniciar la app, antes de dibujar la primera pantalla.
  Future<void> cargar() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      // Se conserva la selección anterior cuando la app actualiza desde
      // versiones que guardaban solo un color.
      final nombre = preferencias.getString(_claveColor) ??
          preferencias.getString('tema_color');
      _paleta = PaletasTema.todas.firstWhere(
        (p) => p.nombre == nombre ||
            (nombre == 'Azul' && p == PaletasTema.predeterminada) ||
            (nombre == 'Verde' && p == PaletasTema.esmeralda) ||
            (nombre == 'Turquesa' && p == PaletasTema.turquesa),
        orElse: () => PaletasTema.predeterminada,
      );
    } catch (error) {
      debugPrint('No se pudo leer el tema guardado: $error');
    }
  }

  Future<void> elegir(PaletaTema paleta) async {
    _paleta = paleta;
    notifyListeners();
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(_claveColor, paleta.nombre);
    } catch (error) {
      debugPrint('No se pudo guardar el tema: $error');
    }
  }
}
