import 'package:flutter/material.dart';

import '../servicios/servicio_inventario.dart';
import '../../servicios/servicio_sesion.dart';
import '../../modelos/usuario.dart';
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
    _servicio.sincronizar();
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

  Future<void> _eliminar(ProductoInventario producto) async {
    try {
      await _servicio.desactivarRemoto(producto.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${producto.nombre} desactivado')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = _servicio.productos;
    final puedeEditar = ServicioSesion.instancia.usuario?.rol == RolUsuario.admin;
    final texto = _busqueda.text.trim().toLowerCase();
    final visibles = productos.where((p) {
      if (_categoria != CategoriaInventario.todos &&
          p.categoria != _categoria) {
        return false;
      }
      return texto.isEmpty || p.nombre.toLowerCase().contains(texto);
    }).toList();

    final stockBajo = productos.where((p) => p.stockBajo).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inventario',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (puedeEditar) FilledButton.icon(
                    onPressed: () => mostrarAgregarProducto(context),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text('Agregar producto', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  if (_servicio.error != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: const Text('No se pudo cargar el inventario'),
                        subtitle: Text(_servicio.error!),
                        trailing: IconButton(
                          tooltip: 'Reintentar',
                          onPressed: _servicio.sincronizar,
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                    ),
                  if (_servicio.cargando && productos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  // Listado
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listado de productos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (visibles.isEmpty && !_servicio.cargando && _servicio.error == null)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No hay productos en el catálogo del servidor.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        for (final p in visibles)
                          FilaProductoInventario(
                            producto: p,
                            onAjustar: () => mostrarAjustarStock(context, p),
                            onEliminar: () => _eliminar(p),
                            puedeEditar: puedeEditar,
                          ),
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
