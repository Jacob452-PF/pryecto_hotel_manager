import 'package:flutter/material.dart';

import '../utilidades/estilos_historial.dart';

/// Etiqueta pequeña con borde (por ejemplo "Cierre" o "#A2").
class EtiquetaPill extends StatelessWidget {
  final String texto;
  const EtiquetaPill(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 11)),
    );
  }
}
