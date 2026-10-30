import 'package:flutter/material.dart';

import '../modelos/turno_caja.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';

/// Aviso de "Modificaciones en gastos de inventario": muestra, por ejemplo,
/// "Se gastó $100.00, pero hubo una modificación y se gastó $60.00".
/// Si ningún gasto se editó, no se ve nada.
class AvisoEdicionesGastos extends StatelessWidget {
  final List<GastoInventarioTurno> gastos;
  const AvisoEdicionesGastos({super.key, required this.gastos});

  String _signo(double v) => '${v < 0 ? '−' : '+'}${dinero(v.abs())}';

  @override
  Widget build(BuildContext context) {
    final editados = gastos.where((g) => g.editado).toList();
    if (editados.isEmpty) return const SizedBox.shrink();

    final antes = gastos.fold(0.0, (s, g) => s + (g.montoOriginal ?? g.monto));
    final ahora = gastos.fold(0.0, (s, g) => s + g.monto);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF8A00)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note, size: 22, color: Color(0xFFEF8A00)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modificaciones en gastos de inventario',
                  style: TextStyle(
                    fontFamily: fuenteTitulo,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final g in editados)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                  children: [
                    TextSpan(
                      text: g.producto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          ': se gastó ${dinero(g.montoOriginal!)}, pero hubo '
                          'una modificación y se gastó ${dinero(g.monto)} '
                          '(${_signo(g.monto - g.montoOriginal!)}).',
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sin modificaciones se habría gastado',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Text(dinero(antes), style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Con modificaciones se gastó',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                dinero(ahora),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
