import 'package:flutter/material.dart';

import '../modelos/periodo_historial.dart';
import '../utilidades/estilos_historial.dart';

/// Chips: Todo, Hoy, Esta semana, Este mes.
class FiltrosPeriodo extends StatelessWidget {
  final PeriodoHistorial seleccionado;
  final ValueChanged<PeriodoHistorial> onCambio;

  const FiltrosPeriodo({
    super.key,
    required this.seleccionado,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final p in PeriodoHistorial.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onCambio(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p == seleccionado ? colores.secondaryContainer : colores.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    p.etiqueta,
                    style: TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 13,
                      color: colores.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (p != PeriodoHistorial.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
