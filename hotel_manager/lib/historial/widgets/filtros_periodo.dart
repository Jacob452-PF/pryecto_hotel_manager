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
                  color: p == seleccionado
                      ? const Color(0xFFBFDCE5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ColoresHistorial.borde),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    p.etiqueta,
                    style: const TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 13,
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
