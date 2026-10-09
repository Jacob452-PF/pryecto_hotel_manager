import 'package:flutter/material.dart';

import 'colores_app.dart';

class PaletaTema {
  final String nombre;
  final Color color;
  const PaletaTema(this.nombre, this.color);
}

/// Colores principales que el usuario puede elegir en "Tema de la app".
/// Todos son oscuros para que el texto blanco se lea bien encima.
class PaletasTema {
  PaletasTema._();

  static const PaletaTema azul = PaletaTema('Azul', ColoresApp.primario);

  static const List<PaletaTema> todas = [
    azul,
    PaletaTema('Verde', Color(0xFF2E7D32)),
    PaletaTema('Turquesa', Color(0xFF00796B)),
    PaletaTema('Morado', Color(0xFF6A1B9A)),
    PaletaTema('Rosa', Color(0xFFAD1457)),
    PaletaTema('Naranja', Color(0xFFD84315)),
    PaletaTema('Café', Color(0xFF5D4037)),
    PaletaTema('Gris azulado', Color(0xFF455A64)),
  ];

  static const PaletaTema predeterminada = azul;
}
