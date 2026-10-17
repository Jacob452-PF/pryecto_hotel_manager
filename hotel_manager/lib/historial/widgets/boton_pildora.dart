import 'package:flutter/material.dart';

import '../utilidades/estilos_historial.dart';

/// Botón grande de abajo ("Cierre de caja", "Cerrar turno").
class BotonPildora extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonPildora({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      // heightFactor: 1 evita que el Center ocupe toda la pantalla.
      child: Center(
        heightFactor: 1,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: ColoresHistorial.boton,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: Text(
            texto,
            style: const TextStyle(
              fontFamily: fuenteTitulo,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
