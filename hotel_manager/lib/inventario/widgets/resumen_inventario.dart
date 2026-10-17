import 'package:flutter/material.dart';

const _azul = Color(0xFF2B8CFF);
const _borde = Color(0xFF7FC8CC);

String _fecha(DateTime d) {
  const meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'pm' : 'am';
  return '${d.day} ${meses[d.month - 1]}.${d.year} - $h:$min $ampm';
}

/// Las 4 tarjetas de resumen: total, stock bajo, en stock y última sincronización.
class ResumenInventario extends StatelessWidget {
  final int total;
  final int stockBajo;
  final int enStock;
  final DateTime ultimaActualizacion;

  const ResumenInventario({
    super.key,
    required this.total,
    required this.stockBajo,
    required this.enStock,
    required this.ultimaActualizacion,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tarjeta(
              icono: Icons.inventory_2,
              etiqueta: 'Total de productos',
              valor: '$total',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              icono: Icons.warning_amber_rounded,
              etiqueta: 'Stock bajo',
              valor: '$stockBajo',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              icono: Icons.check_circle_outline,
              etiqueta: 'En stock',
              valor: '$enStock',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tarjeta(
              icono: Icons.sync,
              etiqueta: 'Última sincronización',
              valor: _fecha(ultimaActualizacion),
              valorPequeno: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool valorPequeno;

  const _Tarjeta({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.valorPequeno = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: _azul),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF2B6CB0)),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              fontSize: valorPequeno ? 10.5 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
