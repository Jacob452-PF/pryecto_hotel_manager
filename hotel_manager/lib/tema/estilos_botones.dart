import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Estilos de botones que se salen del tema general.
class EstilosBotones {
  EstilosBotones._();

  static ButtonStyle get cancelar => OutlinedButton.styleFrom(
    foregroundColor: ColoresApp.cancelar,
    side: const BorderSide(color: ColoresApp.cancelar),
  );
}
