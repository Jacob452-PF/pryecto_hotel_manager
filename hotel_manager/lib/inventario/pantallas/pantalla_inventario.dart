import 'package:flutter/material.dart';

import '../servicios/servicio_inventario.dart';
import '../modelos/producto_inventario.dart';
import '../widgets/chip_categoria_inventario.dart';
import '../widgets/fila_producto_inventario.dart';
import '../widgets/hoja_agregar_producto.dart';
import '../widgets/hoja_ajustar_stock.dart';
import '../widgets/resumen_inventario.dart';

/// Pantalla de Inventario. La barra inferior la maneja ContenedorPrincipal.
class PantallaInventario extends StatefulWidget {
  const PantallaInventario({super.key});

  @override
  State<PantallaInventario> createState() => _EstadoPantallaInventario();
}

class _EstadoPantallaInventario extends State<PantallaInventario> {
  final ServicioInventario _servicio = ServicioInventario.instancia;
  final TextEditingController _busqueda = TextEditingController();
  CategoriaInventario _categoria = CategoriaInventario.todos;

  @override
  void initState() {
    super.initState();
    _servicio.addListener(_refrescar);
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _servicio.removeListener(_refrescar);
    _busqueda.dispose();
    super.dispose();
  }

  void _eliminar(ProductoInventario producto) {
    _servicio.eliminar(producto.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} eliminado'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () => _servicio.restaurar(producto.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final productos = _servicio.productos;
    final texto = _busqueda.text.trim().toLowerCase();
    final visibles = productos.where((p) {
      if (_categoria != CategoriaInventario.todos &&
          p.categoria != _categoria) {
        return false;
      }
      return texto.isEmpty || p.nombre.toLowerCase().contains(texto);
    }).toList();

    final stockBajo = productos.where((p) => p.stockBajo).length;
    final eliminados = _servicio.eliminados;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 34),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Inventario',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => mostrarAgregarProducto(context),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Agregar producto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  // Buscador + categorías
                  _Panel(
                    child: Column(
                      children: [
                        TextField(
                          controller: _busqueda,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar',
                            isDense: true,
                            suffixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final c in CategoriaInventario.values) ...[
                              ChipCategoriaInventario(
                                categoria: c,
                                seleccionada: c == _categoria,
                                onTap: () => setState(() => _categoria = c),
                              ),
                              if (c != CategoriaInventario.values.last)
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ResumenInventario(
                    total: productos.length,
                    stockBajo: stockBajo,
                    enStock: productos.length - stockBajo,
                    ultimaActualizacion: _servicio.ultimaActualizacion,
                  ),
                  const SizedBox(height: 10),
                  // Listado
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Listado de productos',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (visibles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No hay productos que coincidan.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        for (final p in visibles)
                          FilaProductoInventario(
                            producto: p,
                            onAjustar: () => mostrarAjustarStock(context, p),
                            onEliminar: () => _eliminar(p),
                          ),
                        if (eliminados.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Productos eliminados (${eliminados.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          for (final p in eliminados)
                            _FilaEliminada(
                              producto: p,
                              onRestaurar: () => _servicio.restaurar(p.id),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaEliminada extends StatelessWidget {
  final ProductoInventario producto;
  final VoidCallback onRestaurar;

  const _FilaEliminada({required this.producto, required this.onRestaurar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          MiniaturaProducto(imagen: producto.imagen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre, style: const TextStyle(fontSize: 15)),
                Text(
                  '\$${producto.precio.toStringAsFixed(2)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onRestaurar,
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Restaurar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor blanco redondeado que agrupa bloques de la pantalla.
class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
