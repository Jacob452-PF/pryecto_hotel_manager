import 'package:flutter/material.dart';

import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';

/// Las 4 tarjetas de arriba del cierre: ventas, gastos, habitaciones y total.
class ResumenTurno extends StatelessWidget {
  final double ventas;
  final int cantidadVentas;
  final double gastos;
  final int cantidadGastos;
  final int habitacionesOcupadas;
  final int habitacionesTotal;
  final double totalEnCaja;

  const ResumenTurno({
    super.key,
    required this.ventas,
    required this.cantidadVentas,
    required this.gastos,
    required this.cantidadGastos,
    required this.habitacionesOcupadas,
    required this.habitacionesTotal,
    required this.totalEnCaja,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Ventas del turno',
              valor: dinero(ventas),
              detalle: '$cantidadVentas ventas',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Gastos del turno',
              valor: dinero(gastos),
              detalle: '$cantidadGastos registros',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Habitaciones ocupadas',
              valor: '$habitacionesOcupadas/$habitacionesTotal',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Total en caja',
              valor: dinero(totalEnCaja),
              detalle: '(Ventas - Gastos)',
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String? detalle;

  const _Tarjeta({required this.etiqueta, required this.valor, this.detalle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: const TextStyle(
                fontFamily: fuenteTitulo,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (detalle != null)
            Text(
              detalle!,
              style: TextStyle(fontSize: 8.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
