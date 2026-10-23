import 'dart:async';

import 'package:flutter/material.dart';

import '../../historial/historial.dart';
import '../../servicios/servicio_estadias.dart';
import '../../servicios/servicio_habitaciones.dart';
import '../modelos/articulo_tienda.dart';
import '../servicios/carrito_tienda.dart';
import '../../historial/servicios/servicio_consumos.dart';
import '../../inventario/servicios/servicio_inventario.dart';

/// Abre el carrito como hoja inferior (bottom sheet).
Future<void> mostrarCarrito(BuildContext context, CarritoTienda carrito) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.92,
    ),
    builder: (_) => HojaCarrito(carrito: carrito),
  );
}

const _rojo = Color(0xFFE53935);

String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

class HojaCarrito extends StatefulWidget {
  final CarritoTienda carrito;
  const HojaCarrito({super.key, required this.carrito});

  @override
  State<HojaCarrito> createState() => _EstadoHojaCarrito();
}

class _EstadoHojaCarrito extends State<HojaCarrito> {
  CarritoTienda get _c => widget.carrito;

  LineaCarrito? _avisoEliminada; // para la barra "Deshacer"
  Timer? _temporizador;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _eliminar(LineaCarrito linea) {
    _c.eliminar(linea);
    setState(() => _avisoEliminada = linea);
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _avisoEliminada = null);
    });
  }

  void _restaurar(LineaCarrito linea) {
    _c.restaurar(linea);
    if (_avisoEliminada == linea) setState(() => _avisoEliminada = null);
  }

  void _confirmar() {
    final huesped = _c.huesped;
    if (huesped == null || _c.lineas.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    // NUEVO: se revisa que alcance el stock del inventario.
    final items = [
      for (final l in _c.lineas) (id: l.articulo.id, cantidad: l.cantidad),
    ];
    final problema = ServicioInventario.instancia.verificarStock(items);
    if (problema != null) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('$problema. Ajusta la cantidad en el carrito.')),
      );
      return;
    }

    final mensaje =
        '${_dinero(_c.totalPagar)} cargados a ${huesped.nombre} (Hab. ${huesped.habitacion})';
    // TODO: guardar el cargo en la base de datos.
    ServicioConsumos.instancia.registrar(
      cliente: huesped.nombre,
      habitacion: huesped.habitacion,
      lineas: [
        for (final l in _c.lineas)
          LineaConsumo(
            l.articulo.nombre,
            l.articulo.precio,
            l.cantidad,
            l.articulo.seccion == SeccionTienda.servicio
                ? TipoVenta.servicios
                : TipoVenta.productos,
          ),
      ],
    );
    ServicioEstadias.instancia.asegurarEstadiaPredeterminada(
      huesped.habitacion,
    );
    ServicioEstadias.instancia.agregarCargos(huesped.habitacion, [
      for (final linea in _c.lineas)
        (articulo: linea.articulo, cantidad: linea.cantidad),
    ]);

    final solicitoLimpieza = _c.lineas.any((l) =>
        l.articulo.seccion == SeccionTienda.servicio &&
        l.articulo.nombre.toLowerCase().contains('limpieza'));
    if (solicitoLimpieza) {
      ServicioHabitaciones.instancia.solicitarLimpieza(huesped.habitacion);
    }

    // NUEVO: baja el stock en el inventario.
    ServicioInventario.instancia.descontarVenta(items);

    _c.vaciar();
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: colores.primary,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final n = _c.lineas.length;
            return Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado oscuro
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colores.onPrimary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carrito',
                                  style: TextStyle(
                                    color: colores.onPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  n == 0
                                      ? 'Tu carrito está vacío'
                                      : '$n ${n == 1 ? 'producto agregado' : 'productos agregados'}',
                                  style: TextStyle(
                                    color: colores.onPrimary.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Cerrar',
                            style: IconButton.styleFrom(
                              backgroundColor: colores.surfaceContainerHighest,
                              foregroundColor: colores.onSurface,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // Cuerpo blanco
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colores.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  8,
                                ),
                                children: [
                                  for (final l in _c.lineas)
                                    _FilaProducto(
                                      linea: l,
                                      onMenos: () => _c.cambiarCantidad(l, -1),
                                      onMas: () => _c.cambiarCantidad(l, 1),
                                      onEliminar: () => _eliminar(l),
                                    ),
                                  if (n == 0)
                                    const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: Text(
                                          'Agrega productos con el botón +.',
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _fila(
                                    'Subtotal',
                                    _dinero(_c.subtotal),
                                    colorLabel: colores.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 6),
                                  _fila(
                                    'Total',
                                    _dinero(_c.totalPagar),
                                    negrita: true,
                                    colorValor: colores.primary,
                                  ),
                                  const SizedBox(height: 18),
                                  _seccionHuesped(),
                                  if (_c.eliminadas.isNotEmpty)
                                    _seccionEliminados(),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: (n == 0 || _c.huesped == null)
                                      ? null
                                      : _confirmar,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colores.primary,
                                    foregroundColor: colores.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cargar a la habitación',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Barra "X eliminado · Deshacer"
                if (_avisoEliminada != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: colores.inverseSurface,
                      borderRadius: BorderRadius.circular(28),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_avisoEliminada!.articulo.nombre} eliminado',
                                style: TextStyle(
                                  color: colores.onInverseSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _restaurar(_avisoEliminada!),
                              child: Text(
                                'Deshacer',
                                style: TextStyle(
                                  color: colores.primary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fila(
    String label,
    String valor, {
    bool negrita = false,
    Color? colorLabel,
    Color? colorValor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              color: colorLabel ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorValor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _seccionHuesped() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '¿A quién se le carga?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_c.huespedes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay huéspedes en habitaciones ocupadas.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final h in _c.huespedes)
          _TarjetaHuesped(
            nombre: h.nombre,
            habitacion: h.habitacion,
            seleccionado: _c.huesped?.id == h.id,
            onTap: () => _c.seleccionarHuesped(h),
          ),
      ],
    );
  }

  Widget _seccionEliminados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 26),
            const SizedBox(width: 10),
            Text(
              'Productos eliminados (${_c.eliminadas.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        for (final l in _c.eliminadas)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _MiniaturaProducto(imagen: l.articulo.imagen),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.articulo.nombre,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _dinero(l.articulo.precio),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _restaurar(l),
                  icon: const Icon(Icons.sync, size: 20),
                  label: const Text('Restaurar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MiniaturaProducto extends StatelessWidget {
  final String? imagen;
  const _MiniaturaProducto({this.imagen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagen == null
          ? Icon(
              Icons.image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : Image.asset(
              imagen!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  final LineaCarrito linea;
  final VoidCallback onMenos;
  final VoidCallback onMas;
  final VoidCallback onEliminar;

  const _FilaProducto({
    required this.linea,
    required this.onMenos,
    required this.onMas,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _MiniaturaProducto(imagen: linea.articulo.imagen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.articulo.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  _dinero(linea.articulo.precio),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Selector de cantidad
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onMenos,
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 32,
                    height: 36,
                    child: Icon(Icons.remove, size: 20),
                  ),
                ),
                Container(
                  width: 34,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${linea.cantidad}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onMas,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEliminar,
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete, color: _rojo),
          ),
        ],
      ),
    );
  }
}

class _TarjetaHuesped extends StatelessWidget {
  final String nombre;
  final String habitacion;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TarjetaHuesped({
    required this.nombre,
    required this.habitacion,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: seleccionado
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              seleccionado
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Habitación $habitacion',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.bed_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


