import 'package:flutter/material.dart';

import '../servicios/servicio_inventario.dart';

String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

String _hora(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  return '$h:$min ${d.hour >= 12 ? 'p.m.' : 'a.m.'}';
}

/// Apartado "Gastos de inventario": cuánto ha gastado el hotel en comprar
/// productos nuevos o reponer stock desde el último cierre de caja.
class GastosInventario extends StatelessWidget {
  const GastosInventario({super.key});

  static const _maxFilas = 5;

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioInventario.instancia;

    return ListenableBuilder(
      listenable: servicio,
      builder: (context, _) {
        // Las más recientes primero
        final compras = servicio.comprasDelTurno.reversed.toList();
        final visibles = compras.take(_maxFilas).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7FC8CC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_checkout,
                    size: 22,
                    color: Color(0xFF2B8CFF),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Gastos de inventario',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _dinero(servicio.gastoDelTurno),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text(
                'Lo que el hotel gastó en productos desde el último cierre de caja',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              if (compras.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Todavía no hay compras en este turno.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              for (final c in visibles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        c.esNuevo ? Icons.fiber_new : Icons.add_box_outlined,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.producto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${c.esNuevo ? 'Producto nuevo' : 'Reposición'} · '
                              '${c.paquetes} ${c.paquetes == 1 ? 'paquete' : 'paquetes'} × ${_dinero(c.costoPaquete)} · ${_hora(c.fecha)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _dinero(c.total),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (compras.length > _maxFilas)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'y ${compras.length - _maxFilas} más (todas se ven en Cierre de caja)',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
