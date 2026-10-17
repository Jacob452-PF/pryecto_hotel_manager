import 'package:flutter/material.dart';

import '../../inventario/servicios/servicio_inventario.dart';
import '../../servicios/servicio_habitaciones.dart';
import '../datos/articulos_de_inventario.dart';
import '../datos/huespedes_desde_habitaciones.dart';
import '../modelos/articulo_tienda.dart';
import '../servicios/carrito_tienda.dart';
import '../widgets/boton_carrito.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/hoja_carrito.dart';
import '../widgets/seccion_articulos.dart';
import 'pantalla_lista_articulos.dart';

/// Pantalla principal de la Tienda.
/// La barra de navegación inferior NO va aquí: ya la maneja ContenedorPrincipal.
class PantallaTienda extends StatefulWidget {
  const PantallaTienda({super.key});

  @override
  State<PantallaTienda> createState() => _EstadoPantallaTienda();
}

class _EstadoPantallaTienda extends State<PantallaTienda> {
  final TextEditingController _busqueda = TextEditingController();
  final ServicioHabitaciones _habitaciones = ServicioHabitaciones.instancia;
  final ServicioInventario _inventario = ServicioInventario.instancia;
  late final CarritoTienda _carrito = CarritoTienda(
    huespedes: huespedesDeHabitaciones(_habitaciones.habitaciones),
  );
  CategoriaTienda _categoria = CategoriaTienda.todos;

  @override
  void initState() {
    super.initState();
    _habitaciones.addListener(_alCambiarHabitaciones);
    _inventario.addListener(_alCambiarInventario);
  }

  /// Check-in / check-out: la lista de "¿A quién se le carga?" se actualiza sola.
  void _alCambiarHabitaciones() => _carrito.actualizarHuespedes(
    huespedesDeHabitaciones(_habitaciones.habitaciones),
  );

  /// Se agregó, eliminó o restauró un producto en el inventario.
  void _alCambiarInventario() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _habitaciones.removeListener(_alCambiarHabitaciones);
    _inventario.removeListener(_alCambiarInventario);
    _busqueda.dispose();
    _carrito.dispose();
    super.dispose();
  }

  /// Sin filtros se muestran solo 2 artículos por sección (vista previa);
  /// con búsqueda o categoría se muestran todos los que coincidan.
  List<ArticuloTienda> _filtrar(SeccionTienda seccion) {
    final texto = _busqueda.text.trim().toLowerCase();
    final sinFiltros = texto.isEmpty && _categoria == CategoriaTienda.todos;

    final lista = articulosDeTienda().where((a) {
      if (a.seccion != seccion) return false;
      if (_categoria != CategoriaTienda.todos && a.categoria != _categoria) {
        return false;
      }
      if (texto.isNotEmpty && !a.nombre.toLowerCase().contains(texto)) {
        return false;
      }
      return true;
    });
    return sinFiltros ? lista.take(2).toList() : lista.toList();
  }

  void _agregar(ArticuloTienda articulo) {
    _carrito.agregar(articulo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${articulo.nombre} agregado al carrito'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _abrirCarrito() => mostrarCarrito(context, _carrito);

  void _verSeccion(SeccionTienda seccion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PantallaListaArticulos(seccion: seccion, carrito: _carrito),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secciones = SeccionTienda.values
        .map((s) => MapEntry(s, _filtrar(s)))
        .where((e) => e.value.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tienda',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _carrito,
                    builder: (_, __) => BotonCarrito(
                      cantidad: _carrito.total,
                      onTap: _abrirCarrito,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
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
                            for (final c in CategoriaTienda.values) ...[
                              ChipCategoria(
                                categoria: c,
                                seleccionada: c == _categoria,
                                onTap: () => setState(() => _categoria = c),
                              ),
                              if (c != CategoriaTienda.values.last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Panel(
                    child: secciones.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No hay artículos que coincidan con tu búsqueda.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final e in secciones)
                                SeccionArticulos(
                                  seccion: e.key,
                                  articulos: e.value,
                                  onAgregar: _agregar,
                                  onVerTodo: () => _verSeccion(e.key),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
