import 'package:flutter/material.dart';

import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';

class LineaFactura {
  final String descripcion;
  final double monto;
  final VoidCallback?
  alQuitar; // si no es null, muestra una "x" para quitar la línea
  const LineaFactura(this.descripcion, this.monto, {this.alQuitar});
}

/// Factura con las líneas de la reserva y el total.
class ResumenFactura extends StatelessWidget {
  final String? detalle;
  final List<LineaFactura> lineas;
  final double total;

  const ResumenFactura({
    super.key,
    required this.lineas,
    required this.total,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detalle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(detalle!, style: EstilosTexto.detalleFactura),
          ),
        for (final linea in lineas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    linea.descripcion,
                    style: EstilosTexto.textoFactura,
                  ),
                ),
                Text(
                  formatearDinero(linea.monto),
                  style: EstilosTexto.textoFactura,
                ),
                SizedBox(
                  width: 28,
                  child: linea.alQuitar == null
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          icon: const Icon(Icons.close),
                          onPressed: linea.alQuitar,
                        ),
                ),
              ],
            ),
          ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: EstilosTexto.totalFactura),
            Text(formatearDinero(total), style: EstilosTexto.totalFactura),
          ],
        ),
      ],
    );
  }
}
