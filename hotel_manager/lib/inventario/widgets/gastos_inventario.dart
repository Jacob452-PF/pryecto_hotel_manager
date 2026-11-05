import 'package:flutter/material.dart';

import '../servicios/servicio_inventario.dart';
import 'hoja_editar_compra.dart';

String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

String _hora(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  return '$h:$min ${d.hour >= 12 ? 'p.m.' : 'a.m.'}';
}

/// Apartado "Gastos de inventario": cuánto ha gastado el hotel en comprar
/// productos nuevos o reponer stock desde el último cierre de caja.
/// Cada compra tiene su botón de editar por si hubo un error.
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7FC8CC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_checkout,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
              Text(
                'Lo que el hotel gastó en productos desde el último cierre de caja',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          c.esNuevo ? Icons.fiber_new : Icons.add_box_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${c.esNuevo ? 'Producto nuevo' : 'Reposición'} · '
                              '${c.paquetes} ${c.paquetes == 1 ? 'paquete' : 'paquetes'} × ${_dinero(c.costoPaquete)} · ${_hora(c.fecha)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            // Si se corrigió: lo que se gastó antes y ahora
                            if (c.editada)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Editado: se había anotado ${_dinero(c.totalOriginal)} y ahora son ${_dinero(c.total)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF8A00),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _dinero(c.total),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Botón de editar, a la par de la compra
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => mostrarEditarCompra(context, c),
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: const Color(0xFF2B8CFF),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
