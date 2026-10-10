import 'package:flutter/material.dart';

import '../datos/articulos_mock.dart';
import '../modelos/articulo_tienda.dart';
import '../servicios/carrito_tienda.dart';
import '../widgets/tarjeta_articulo.dart';

/// Pantalla con TODOS los artículos de una sección
/// (Habitaciones, Servicio o Productos del hotel).
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

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<ArticuloTienda> get _articulos {
    final texto = _busqueda.text.trim().toLowerCase();
    return articulosMock
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
      backgroundColor: const Color(0xFFF3F0F8),
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
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Artículos en el carrito: ${widget.carrito.total}',
                          ),
                        ),
                      ),
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7FC8CC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E56A8),
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
                decoration: const BoxDecoration(
                  color: Colors.white,
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
