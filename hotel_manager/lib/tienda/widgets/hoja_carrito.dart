import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../servicios/api_client.dart';
import '../servicios/carrito_tienda.dart';
import '../../inventario/servicios/servicio_inventario.dart';
import '../../servicios/servicio_huespedes.dart';
import '../../widgets/dialogo_cobro.dart';

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
  bool _enviando = false;

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

  Future<void> _confirmar() async {
    if (_enviando || _c.lineas.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final modo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cómo deseas registrar la venta?'),
        content: const Text(
          'Puedes pagar ahora sin asignar un cliente o cargar los productos a una habitación ocupada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'estadia'),
            child: const Text('Cargar a habitación'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'ahora'),
            child: const Text('Pagar ahora'),
          ),
        ],
      ),
    );
    if (modo == null || !mounted) return;

    if (modo == 'ahora') {
      final cliente = await _pedirDatosFactura();
      if (cliente == null || !mounted) return;
      final pago = await mostrarDialogoCobro(context, saldo: _c.totalPagar);
      if (pago == null || !mounted) return;
      final items = <Map<String, int>>[];
      for (final line in _c.lineas) {
        final id = int.tryParse(line.articulo.id);
        if (id == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'El producto no pertenece al inventario del servidor.',
              ),
            ),
          );
          return;
        }
        items.add({'product_id': id, 'quantity': line.cantidad});
      }
      final guestId = int.tryParse(cliente['guest_id']?.toString() ?? '');
      if (cliente['guest_id'] != null && guestId == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('El cliente seleccionado no tiene un ID válido.'),
          ),
        );
        return;
      }
      setState(() => _enviando = true);
      try {
        final venta = await ApiClient.instance.createSale(
          paymentMethod: pago.metodo.name,
          items: items,
          guestId: guestId,
          customerName: cliente['customer_name']?.toString(),
          customerDocument: cliente['customer_document']?.toString(),
          customerPhone: cliente['customer_phone']?.toString(),
        );
        await ServicioInventario.instancia.sincronizar();
        if (!mounted) return;
        await _mostrarFacturaVenta(venta);
        if (!mounted) return;
        _c.vaciar();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente.')),
        );
      } on Object catch (error) {
        if (mounted)
          messenger.showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
      } finally {
        if (mounted) setState(() => _enviando = false);
      }
      return;
    }

    final huesped = _c.huesped;
    final stayId = huesped?.estadiaIdApi;
    if (huesped == null || stayId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una habitación ocupada para cargar el consumo.',
          ),
        ),
      );
      return;
    }
    final pagarAhora = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cobro de habitación'),
        content: Text(
          '¿Cobrar ahora ${_dinero(_c.totalPagar)} o agregarlo al saldo de la habitación ${huesped.habitacion}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cargar al saldo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cobrar ahora'),
          ),
        ],
      ),
    );
    if (pagarAhora == null || !mounted) return;
    final pago = pagarAhora
        ? await mostrarDialogoCobro(context, saldo: _c.totalPagar)
        : null;
    if (pagarAhora && (pago == null || !mounted)) return;

    setState(() => _enviando = true);
    try {
      await ApiClient.instance.chargeStay(
        stayId,
        items: [
          for (final line in _c.lineas)
            {
              'product_id': int.parse(line.articulo.id),
              'quantity': line.cantidad,
            },
        ],
        payNow: pagarAhora,
        paymentMethod: pago?.metodo.name,
      );
      await ServicioInventario.instancia.sincronizar();
      if (!mounted) return;
      final mensaje = pagarAhora
          ? 'Pago de ${_dinero(_c.totalPagar)} registrado para ${huesped.nombre}.'
          : 'Consumo agregado al saldo de ${huesped.nombre}.';
      _c.vaciar();
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(mensaje)));
    } on Object catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<Map<String, dynamic>?> _pedirDatosFactura() async {
    final huespedes = ServicioHuespedes.instancia.huespedes;
    final nombre = TextEditingController();
    final documento = TextEditingController();
    final telefono = TextEditingController();
    String? seleccionado;
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) => AlertDialog(
          title: const Text('Datos para la factura (opcional)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: '',
                  decoration: const InputDecoration(
                    labelText: 'Cliente registrado',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sin cliente registrado'),
                    ),
                    for (final h in huespedes)
                      DropdownMenuItem(
                        value: h.id,
                        child: Text(h.nombre, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) {
                    seleccionado = id == null || id.isEmpty ? null : id;
                    final h = huespedes
                        .where((x) => x.id == seleccionado)
                        .firstOrNull;
                    nombre.text = h?.nombre ?? '';
                    documento.text = h?.dui ?? '';
                    telefono.text = h?.telefono ?? '';
                    actualizar(() {});
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                  ),
                ),
                TextField(
                  controller: documento,
                  decoration: const InputDecoration(
                    labelText: 'Documento (opcional)',
                  ),
                ),
                TextField(
                  controller: telefono,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, <String, dynamic>{}),
              child: const Text('Sin datos'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                if (seleccionado != null) 'guest_id': seleccionado,
                'customer_name': nombre.text.trim(),
                'customer_document': documento.text.trim(),
                'customer_phone': telefono.text.trim(),
              }),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    nombre.dispose();
    documento.dispose();
    telefono.dispose();
    return datos;
  }

  Future<void> _mostrarFacturaVenta(Map<String, dynamic> venta) async {
    final items = venta['items'] is List ? (venta['items'] as List) : const [];
    final guest = venta['guest'] is Map
        ? Map<String, dynamic>.from(venta['guest'] as Map)
        : const <String, dynamic>{};
    final cliente =
        guest['name'] ?? venta['customer_name'] ?? 'Cliente sin registrar';
    final documento = guest['document'] ?? venta['customer_document'];
    final telefono = guest['phone'] ?? venta['customer_phone'];
    final total =
        double.tryParse(venta['total']?.toString() ?? '') ?? _c.totalPagar;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factura de tienda'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Factura #${venta['id'] ?? '—'}'),
                Text('Fecha: ${venta['created_at'] ?? 'Ahora'}'),
                Text('Cliente: $cliente'),
                if (documento != null && documento.toString().isNotEmpty)
                  Text('Documento: $documento'),
                if (telefono != null && telefono.toString().isNotEmpty)
                  Text('Teléfono: $telefono'),
                const Divider(),
                for (final raw in items.whereType<Map>())
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${(raw['product'] as Map?)?['name'] ?? 'Producto'} × ${raw['quantity'] ?? 1}  ·  ${_dinero(double.tryParse(raw['subtotal']?.toString() ?? '') ?? ((double.tryParse(raw['unit_price']?.toString() ?? '') ?? 0) * (int.tryParse(raw['quantity']?.toString() ?? '') ?? 1)))}',
                    ),
                  ),
                const Divider(),
                Text(
                  'Total: ${_dinero(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text('Pago: ${venta['payment_method'] ?? 'Registrado'}'),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar factura'),
          ),
        ],
      ),
    );
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
                                  onPressed: (n == 0 || _enviando)
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
                                  child: Text(
                                    _enviando
                                        ? 'Registrando…'
                                        : 'Continuar al cobro',
                                    style: const TextStyle(fontSize: 16),
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
              'Asignación de la compra (opcional)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Elige una habitación si quieres cargar los productos a una estadía. Para pagar ahora no necesitas seleccionar a nadie.',
        ),
        const SizedBox(height: 10),
        if (_c.huesped != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _c.quitarHuespedSeleccionado,
              icon: const Icon(Icons.close),
              label: const Text('Quitar habitación'),
            ),
          ),
        if (_c.huespedes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay habitaciones con estadía activa para cargar consumos.',
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
                _MiniaturaProducto(
                  imagen: l.articulo.imagen,
                  imagenBytes: l.articulo.imagenBytes,
                ),
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
  final Uint8List? imagenBytes;
  const _MiniaturaProducto({this.imagen, this.imagenBytes});

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
      child: imagenBytes != null
          ? Image.memory(imagenBytes!, fit: BoxFit.cover)
          : imagen == null
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
          _MiniaturaProducto(
            imagen: linea.articulo.imagen,
            imagenBytes: linea.articulo.imagenBytes,
          ),
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
