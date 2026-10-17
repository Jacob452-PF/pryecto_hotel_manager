import 'package:flutter/material.dart';

import 'pantalla_lista_cajas.dart';

/// Pantalla que se conecta en ContenedorPrincipal (pestaña "Historial").
///
/// Tiene su propio Navigator: así "Cierre de caja" y "Detalle de caja" se abren
/// DENTRO de la pestaña y la barra de navegación de abajo sigue visible.
class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => PantallaListaCajas(),
      ),
    );
  }
}
