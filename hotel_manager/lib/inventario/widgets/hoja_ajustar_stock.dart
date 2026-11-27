import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import '../tema_inventario.dart';
import 'dialogo_inventario.dart';
import 'fila_producto_inventario.dart';

/// Ventana para corregir existencias, reponer unidades y registrar devoluciones.
Future<void> mostrarAjustarStock(
  BuildContext context,
  ProductoInventario producto,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => Theme(
      data: temaInventario(context),
      child: _DialogoAjustar(producto: producto),
    ),
  );
}

const _motivos = [
  'Corrección de inventario',
  'Reposición de stock',
  'Devolución',
];
const _tiposDevolucion = ['De cliente', 'A proveedor'];

class _DialogoAjustar extends StatefulWidget {
  final ProductoInventario producto;
  const _DialogoAjustar({required this.producto});

  @override
  State<_DialogoAjustar> createState() => _EstadoDialogoAjustar();
}

class _EstadoDialogoAjustar extends State<_DialogoAjustar> {
  late final TextEditingController _stock = TextEditingController(
    text: '${widget.producto.stock}',
  );
  final TextEditingController _nota = TextEditingController();

  final TextEditingController _paquetes = TextEditingController(text: '1');
  late final TextEditingController _costo = TextEditingController(
    text: widget.producto.costoUnitario > 0
        ? widget.producto.costoUnitario.toStringAsFixed(2)
        : '',
  );
  late final TextEditingController _precioVenta = TextEditingController(
    text: widget.producto.precio.toStringAsFixed(2),
  );
  late final TextEditingController _precioDevolucion = TextEditingController(
    text: widget.producto.precio.toStringAsFixed(2),
  );
  late bool _actualizarPrecio = widget.producto.costoUnitario <= 0;
  bool _precioEditadoManualmente = false;

  String _motivo = _motivos.first;
  String _tipoDevolucion = _tiposDevolucion.first;
  String? _error;

  @override
  void dispose() {
    _stock.dispose();
    _nota.dispose();
    _paquetes.dispose();
    _costo.dispose();
    _precioVenta.dispose();
    _precioDevolucion.dispose();
    super.dispose();
  }

  bool get _esReposicion => _motivo == 'Reposición de stock';
  bool get _esDevolucion => _motivo == 'Devolución';
  bool get _esDevolucionCliente => _tipoDevolucion == 'De cliente';

  double? _leerDinero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  int get _numPaquetes => int.tryParse(_paquetes.text.trim()) ?? 0;
  int get _unidadesQueEntran => _numPaquetes;
  int get _stockResultante => widget.producto.stock + _unidadesQueEntran;

  String _d(double v) => '\$${v.toStringAsFixed(2)}';

  void _sumar(int delta) {
    setState(() {
      _error = null;
      var nuevo = (int.tryParse(_stock.text.trim()) ?? 0) + delta;
      if (nuevo < 0) nuevo = 0;
      _stock.text = '$nuevo';
    });
  }

  void _costoCambiado(String _) {
    final costo = _leerDinero(_costo.text);
    final costoActual = widget.producto.costoUnitario;
    if (!_precioEditadoManualmente && costo != null && costo > 0) {
      _precioVenta.text = precioDeVenta(costo).toStringAsFixed(2);
    }
    setState(() {
      _error = null;
      _actualizarPrecio =
          costoActual <= 0 ||
          (costo != null && (costo - costoActual).abs() > 0.001);
    });
  }

  Future<void> _guardar() async {
    final servicio = ServicioInventario.instancia;
    final p = widget.producto;

    if (_esReposicion) {
      final costo = _leerDinero(_costo.text);
      if (_numPaquetes < 1) {
        setState(() => _error = 'Escribe cuántos productos agregaste.');
        return;
      }
      if (costo == null || costo < 0) {
        setState(
          () => _error =
              'Escribe cuánto costó cada producto (0 si no tuvo costo).',
        );
        return;
      }
      final precio = _leerDinero(_precioVenta.text);
      if (_actualizarPrecio &&
          (precio == null || !precio.isFinite || precio < 0)) {
        setState(() => _error = 'Escribe un precio de venta válido.');
        return;
      }
      try {
        await servicio.reponerStockRemoto(
          p.id,
          cantidad: _numPaquetes,
          costoUnitario: costo,
          precioVenta: _actualizarPrecio ? precio : null,
        );
        if (mounted) Navigator.of(context).pop();
      } on Object catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
      return;
    }

    if (_esDevolucion) {
      final cantidad = _numPaquetes;
      final precio = _leerDinero(_precioDevolucion.text);
      if (cantidad < 1) {
        setState(() => _error = 'Escribe cuántos productos se devuelven.');
        return;
      }
      if (precio == null || !precio.isFinite || precio < 0) {
        setState(() => _error = 'Escribe un precio válido para la devolución.');
        return;
      }
      if (!_esDevolucionCliente && cantidad > p.stock) {
        setState(
          () => _error =
              'Solo hay ${p.stock} unidades disponibles para devolver.',
        );
        return;
      }
      try {
        await servicio.actualizarStockRemoto(
          p.id,
          stock: _esDevolucionCliente ? p.stock + cantidad : p.stock - cantidad,
          motivo: _nota.text.trim().isEmpty
              ? 'Devolución ${_esDevolucionCliente ? 'de cliente' : 'a proveedor'}'
              : _nota.text.trim(),
        );
        if (mounted) Navigator.of(context).pop();
      } on Object catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
      return;
    }

    final stock = int.tryParse(_stock.text.trim());
    if (stock == null) {
      setState(() => _error = 'Escribe un número válido.');
      return;
    }
    try {
      await servicio.actualizarStockRemoto(
        p.id,
        stock: stock,
        motivo: _nota.text.trim().isEmpty ? _motivo : _nota.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  InputDecoration _decoracion({
    String? etiqueta,
    String? pista,
    String? prefijo,
    String? ayuda,
    Color? relleno,
  }) {
    final colores = Theme.of(context).colorScheme;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colores.outline),
    );
    return InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      prefixText: prefijo,
      helperText: ayuda,
      helperMaxLines: 2,
      filled: true,
      fillColor: relleno ?? colores.surfaceContainerHighest,
      border: borde,
      enabledBorder: borde,
      focusedBorder: borde.copyWith(
        borderSide: BorderSide(color: colores.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colores.onSurfaceVariant),
      hintStyle: TextStyle(color: colores.onSurfaceVariant),
      helperStyle: TextStyle(color: colores.onSurfaceVariant),
      prefixStyle: TextStyle(color: colores.onSurface),
    );
  }

  /// Cantidad, costo unitario y precio sugerido/editable de la reposición.
  Widget _panelReposicion() {
    final p = widget.producto;
    final costo = _leerDinero(_costo.text) ?? 0.0;
    final hayDatos = _numPaquetes > 0;
    final precioNuevo = _leerDinero(_precioVenta.text) ?? p.precio;
    final cambioCosto =
        p.costoUnitario > 0 && costo > 0 && costo != p.costoUnitario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Entrada de productos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _costo,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: _costoCambiado,
          decoration: _decoracion(
            etiqueta: 'Costo por producto',
            prefijo: '\$ ',
            ayuda: p.costoUnitario > 0
                ? 'Costo anterior: ${_d(p.costoUnitario)} por unidad.'
                : 'Lo que le costó al hotel cada unidad.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paquetes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: _decoracion(etiqueta: 'Productos que deseas agregar'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _precioVenta,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          enabled: _actualizarPrecio,
          onChanged: (_) => setState(() => _precioEditadoManualmente = true),
          decoration: _decoracion(
            etiqueta: 'Precio de venta por producto',
            prefijo: '\$ ',
            ayuda:
                'Sugerido con ${((margenGanancia) * 100).round()}% de ganancia; puedes cambiarlo.',
          ),
        ),
        const SizedBox(height: 12),
        ResumenCompra(
          filas: [
            FilaResumen('Unidades que entran', '$_unidadesQueEntran'),
            FilaResumen('Stock después de agregar', '$_stockResultante'),
            FilaResumen('Costo por unidad', _d(costo)),
            FilaResumen(
              'Gasto total ($_numPaquetes × ${_d(costo)})',
              _d(_numPaquetes * costo),
            ),
            FilaResumen(
              'Precio de venta',
              hayDatos ? _d(precioNuevo) : _d(p.precio),
              destacar: true,
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _actualizarPrecio,
          onChanged: (v) => setState(() => _actualizarPrecio = v),
          title: Text(
            cambioCosto
                ? 'Cambió el costo: actualizar el precio de venta'
                : 'Actualizar el precio de venta',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _panelDevolucion() {
    final cantidad = _numPaquetes;
    final precio = _leerDinero(_precioDevolucion.text) ?? 0;
    final importe = cantidad * precio;
    final stockResultante = _esDevolucionCliente
        ? widget.producto.stock + cantidad
        : widget.producto.stock - cantidad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Tipo de devolución',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipoDevolucion,
          decoration: _decoracion(),
          items: [
            for (final tipo in _tiposDevolucion)
              DropdownMenuItem(value: tipo, child: Text(tipo)),
          ],
          onChanged: (tipo) => setState(() {
            _tipoDevolucion = tipo ?? _tipoDevolucion;
            _error = null;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paquetes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: _decoracion(etiqueta: 'Cantidad de productos'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _precioDevolucion,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: _decoracion(
            etiqueta: _esDevolucionCliente
                ? 'Reembolso por producto'
                : 'Importe devuelto por el proveedor (por producto)',
            prefijo: '\$ ',
          ),
        ),
        const SizedBox(height: 12),
        ResumenCompra(
          filas: [
            FilaResumen(
              'Importe de la devolución',
              _d(importe),
              destacar: true,
            ),
            FilaResumen('Stock después del movimiento', '$stockResultante'),
            FilaResumen(
              'Registro en gastos',
              _esDevolucionCliente ? 'Reembolso' : 'Reduce el gasto neto',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return DialogoInventario(
      icono: Icons.tune,
      titulo: 'Ajustar producto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta gris: producto + nuevo stock
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MiniaturaProducto(
                      imagen: p.imagen,
                      imagenBytes: p.imagenBytes,
                      tamano: 56,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Precio: ${_d(p.precio)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EstadoActual(producto: p),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _esReposicion
                      ? 'Stock después de agregar'
                      : _esDevolucion
                      ? 'Stock después de la devolución'
                      : 'Nuevo stock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!_esReposicion && !_esDevolucion) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Escribe el stock final que debe quedar.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stock,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 17),
                          decoration: _decoracion(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _BotonCuadrado(
                        icono: Icons.remove,
                        onTap: () => _sumar(-1),
                      ),
                      const SizedBox(width: 8),
                      _BotonCuadrado(icono: Icons.add, onTap: () => _sumar(1)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Motivo del ajuste',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: _decoracion().copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _motivo,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                items: [
                  for (final m in _motivos)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() {
                  _motivo = v ?? _motivo;
                  _error = null;
                }),
              ),
            ),
          ),
          if (_esReposicion) _panelReposicion(),
          if (_esDevolucion) _panelDevolucion(),
          const SizedBox(height: 18),
          const Text(
            'Nota (opcional)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nota,
            minLines: 3,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoracion(pista: 'Añade una nota sobre el ajuste...'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 20),
          BotonesDialogo(
            textoGuardar: 'Guardar cambios',
            onGuardar: _guardar,
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _BotonCuadrado extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BotonCuadrado({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Icon(icono, size: 24),
        ),
      ),
    );
  }
}

/// "• Stock actual: 48/50" y la etiqueta de estado (En stock / Stock bajo / Agotado).
class _EstadoActual extends StatelessWidget {
  final ProductoInventario producto;
  const _EstadoActual({required this.producto});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final String texto;
    final Color color;
    final Color fondo;
    if (producto.agotado) {
      texto = 'Agotado';
      color = const Color(0xFFE53935);
      fondo = tema.colorScheme.errorContainer;
    } else if (producto.stockBajo) {
      texto = 'Stock bajo';
      color = const Color(0xFFEF8A00);
      fondo = tema.colorScheme.tertiaryContainer;
    } else {
      texto = 'En stock';
      color = const Color(0xFF22A559);
      fondo = tema.colorScheme.secondaryContainer;
    }

    Widget punto() => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            punto(),
            const SizedBox(width: 5),
            Text(
              'Stock actual: ${producto.stock} · mínimo ${producto.stockMinimo}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              punto(),
              const SizedBox(width: 5),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
