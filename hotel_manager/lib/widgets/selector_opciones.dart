import 'package:flutter/material.dart';

import 'opcion_recuadro.dart';

/// Fila de recuadros seleccionables. Sirve para cualquier tipo de opción.
/// Si [seleccionada] es null, no hay ninguna opción marcada.
class SelectorOpciones<T> extends StatelessWidget {
  final List<T> opciones;
  final T? seleccionada;
  final String Function(T) etiqueta;
  final IconData? Function(T)? icono;
  final String? Function(T)? detalle;
  final ValueChanged<T> alCambiar;

  const SelectorOpciones({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.etiqueta,
    required this.alCambiar,
    this.icono,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones
          .map(
            (opcion) => OpcionRecuadro(
              etiqueta: etiqueta(opcion),
              icono: icono?.call(opcion),
              detalle: detalle?.call(opcion),
              seleccionada: opcion == seleccionada,
              alTocar: () => alCambiar(opcion),
            ),
          )
          .toList(),
    );
  }
}
