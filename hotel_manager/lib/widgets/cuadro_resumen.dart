import 'package:flutter/material.dart';

import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

class DatoResumen {
  final String etiqueta;
  final int cantidad;
  final Color color;
  final IconData icono;
  DatoResumen(this.etiqueta, this.cantidad, this.color, this.icono);
}

class CuadroResumen extends StatelessWidget {
  final DatoResumen dato;
  const CuadroResumen({super.key, required this.dato});

  @override
  Widget build(BuildContext context) {
    const columnas = 2;
    // 32 = margen lateral de la pantalla, 10 = espacio entre cuadros
    final ancho =
        (MediaQuery.of(context).size.width - 32 - 10 * (columnas - 1)) /
        columnas;
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: dato.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        border: Border.all(color: dato.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(dato.icono, color: dato.color),
          const SizedBox(height: 4),
          Text(
            '${dato.cantidad}',
            style: EstilosTexto.numeroResumen.copyWith(color: dato.color),
          ),
          Text(
            dato.etiqueta,
            textAlign: TextAlign.center,
            style: EstilosTexto.etiquetaResumen,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
