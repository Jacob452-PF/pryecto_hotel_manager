import 'package:flutter/material.dart';

import '../../inventario/servicios/servicio_inventario.dart';
import '../datos/articulos_de_inventario.dart';
import '../modelos/articulo_tienda.dart';
import '../servicios/carrito_tienda.dart';
import '../widgets/hoja_carrito.dart';
import '../widgets/tarjeta_articulo.dart';

/// Pantalla con TODOS los artículos de una sección
/// (Servicio o Productos del hotel).
/// Se abre con la flecha ">" de cada sección en PantallaTienda.
class PantallaListaArticulos extends StatefulWidget {
  final SeccionTienda seccion;
  final CarritoTienda carrito;

  const PantallaListaArticulos({
    super.key,
    required this.seccion,
    required this.carrito,
  });

  @override
  State<PantallaListaArticulos> createState() => _EstadoPantallaLista();
}

class _EstadoPantallaLista extends State<PantallaListaArticulos> {
  final TextEditingController _busqueda = TextEditingController();
  final ServicioInventario _inventario = ServicioInventario.instancia;

  @override
  void initState() {
    super.initState();
    _inventario.addListener(_refrescar);
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inventario.removeListener(_refrescar);
    _busqueda.dispose();
    super.dispose();
  }

  List<ArticuloTienda> get _articulos {
    final texto = _busqueda.text.trim().toLowerCase();
    return articulosDeTienda()
        .where(
          (a) =>
              a.seccion == widget.seccion &&
              (texto.isEmpty || a.nombre.toLowerCase().contains(texto)),
        )
        .toList();
  }

  void _agregar(ArticuloTienda articulo) {
    widget.carrito.agregar(articulo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${articulo.nombre} agregado al carrito'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final articulos = _articulos;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado: flecha atrás, título y bolsa
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Volver',
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      widget.seccion.titulo.toLowerCase(),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: widget.carrito,
                    builder: (_, __) => IconButton(
                      onPressed: () => mostrarCarrito(context, widget.carrito),
                      tooltip: 'Carrito',
                      icon: Badge(
                        isLabelVisible: widget.carrito.total > 0,
                        label: Text('${widget.carrito.total}'),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _busqueda,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Panel blanco con la cuadrícula
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: articulos.isEmpty
                    ? const Center(child: Text('No se encontraron artículos.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: articulos.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.05,
                            ),
                        itemBuilder: (_, i) => TarjetaArticulo(
                          articulo: articulos[i],
                          onAgregar: () => _agregar(articulos[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
