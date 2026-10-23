import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import 'dialogo_inventario.dart';
import 'fila_producto_inventario.dart';

/// Ventana "Ajustar producto": nuevo stock, motivo del ajuste y nota.
/// Con el motivo "Reposición de stock" se compran PAQUETES: se puede cambiar
/// el costo del paquete (si subió de precio) y el precio de venta se
/// recalcula solo (costo por unidad + 30%).
Future<void> mostrarAjustarStock(
  BuildContext context,
  ProductoInventario producto,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoAjustar(producto: producto),
  );
}

const _motivoReposicion = 'Reposición de stock';
const _motivos = [
  'Merma',
  _motivoReposicion,
  'Corrección de inventario',
  'Devolución',
  'Otro',
];

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

  // Solo para "Reposición de stock"
  final TextEditingController _paquetes = TextEditingController(text: '1');
  late final TextEditingController _unidades = TextEditingController(
    text: '${widget.producto.unidadesPorPaquete}',
  );
  late final TextEditingController _costo = TextEditingController(
    text: widget.producto.costoPaquete > 0
        ? widget.producto.costoPaquete.toStringAsFixed(2)
        : '',
  );
  bool _actualizarPrecio = true;

  String _motivo = _motivos.first;
  String? _error;

  @override
  void dispose() {
    _stock.dispose();
    _nota.dispose();
    _paquetes.dispose();
    _unidades.dispose();
    _costo.dispose();
    super.dispose();
  }

  bool get _esReposicion => _motivo == _motivoReposicion;

  double? _leerDinero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  int get _numPaquetes => int.tryParse(_paquetes.text.trim()) ?? 0;
  int get _numUnidades => int.tryParse(_unidades.text.trim()) ?? 0;
  int get _unidadesQueEntran => _numPaquetes * _numUnidades;
  int get _stockResultante => widget.producto.stock + _unidadesQueEntran;

  String _d(double v) => '\$${v.toStringAsFixed(2)}';

  /// En reposición los botones − y + cambian los paquetes; en los demás
  /// motivos cambian el stock de uno en uno.
  void _sumar(int delta) {
    setState(() {
      _error = null;
      if (_esReposicion) {
        final nuevo = _numPaquetes + delta;
        _paquetes.text = '${nuevo < 0 ? 0 : nuevo}';
      } else {
        var nuevo = (int.tryParse(_stock.text.trim()) ?? 0) + delta;
        if (nuevo < 0) nuevo = 0;
        if (nuevo > widget.producto.stockMaximo) {
          nuevo = widget.producto.stockMaximo;
        }
        _stock.text = '$nuevo';
      }
    });
  }

  void _guardar() {
    final servicio = ServicioInventario.instancia;
    final p = widget.producto;

    if (_esReposicion) {
      final costo = _leerDinero(_costo.text);
      if (_numPaquetes < 1) {
        setState(() => _error = 'Escribe cuántos paquetes compraste.');
        return;
      }
      if (_numUnidades < 1) {
        setState(() => _error = 'Escribe cuántas unidades trae cada paquete.');
        return;
      }
      if (costo == null || costo < 0) {
        setState(
          () =>
              _error = 'Escribe cuánto costó el paquete (0 si no tuvo costo).',
        );
        return;
      }
      servicio.reponerStock(
        p.id,
        paquetes: _numPaquetes,
        unidadesPorPaquete: _numUnidades,
        costoPaquete: costo,
        actualizarPrecio: _actualizarPrecio,
        nota: _nota.text.trim(),
      );
      Navigator.of(context).pop();
      return;
    }

    final stock = int.tryParse(_stock.text.trim());
    if (stock == null) {
      setState(() => _error = 'Escribe un número válido.');
      return;
    }
    if (stock > p.stockMaximo) {
      setState(
        () => _error = 'No puede superar el stock máximo (${p.stockMaximo}).',
      );
      return;
    }
    servicio.actualizarStock(
      p.id,
      stock: stock,
      motivo: _motivo,
      nota: _nota.text.trim(),
    );
    Navigator.of(context).pop();
  }

  InputDecoration _decoracion({
    String? etiqueta,
    String? pista,
    String? prefijo,
    String? ayuda,
    Color? relleno,
  }) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF9A9AA5)),
    );
    return InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      prefixText: prefijo,
      helperText: ayuda,
      helperMaxLines: 2,
      filled: true,
      fillColor: relleno ?? const Color(0xFFF6F6F9),
      border: borde,
      enabledBorder: borde,
    );
  }

  /// Campos y cuentas de la compra de paquetes.
  Widget _panelReposicion() {
    final p = widget.producto;
    final costo = _leerDinero(_costo.text) ?? 0.0;
    final unidades = _numUnidades;
    final hayDatos = costo > 0 && unidades > 0;
    final costoUnidad = hayDatos ? costo / unidades : 0.0;
    final precioNuevo = hayDatos ? precioDeVenta(costoUnidad) : p.precio;
    final cambioCosto =
        p.costoPaquete > 0 && costo > 0 && costo != p.costoPaquete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Compra del paquete',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _costo,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: _decoracion(
            etiqueta: 'Costo del paquete',
            prefijo: '\$ ',
            ayuda: p.costoPaquete > 0
                ? 'Antes: ${_d(p.costoPaquete)}. Si subió de precio, escribe el nuevo costo.'
                : 'Lo que le costó al hotel cada paquete.',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paquetes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: _decoracion(etiqueta: 'Paquetes comprados'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unidades,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: _decoracion(etiqueta: 'Unidades por paquete'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResumenCompra(
          filas: [
            FilaResumen('Unidades que entran', '$_unidadesQueEntran'),
            FilaResumen('Costo por unidad', hayDatos ? _d(costoUnidad) : '—'),
            FilaResumen(
              'Gasto total ($_numPaquetes × ${costo > 0 ? _d(costo) : '—'})',
              hayDatos ? _d(_numPaquetes * costo) : '—',
            ),
            FilaResumen(
              'Precio de venta (+20%)',
              hayDatos ? _d(precioNuevo) : _d(p.precio),
              destacar: true,
            ),
            if (hayDatos && precioNuevo != p.precio)
              FilaResumen('Precio actual', _d(p.precio)),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _actualizarPrecio,
          onChanged: (v) => setState(() => _actualizarPrecio = v),
          title: Text(
            cambioCosto
                ? 'El paquete cambió de precio: actualizar precio de venta'
                : 'Actualizar el precio de venta',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (_stockResultante > p.stockMaximo)
          Text(
            'El stock máximo subirá a $_stockResultante.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF55555F)),
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
              color: const Color(0xFFEFF1F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MiniaturaProducto(imagen: p.imagen, tamano: 56),
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
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF55555F),
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
                const Text(
                  'Nuevo stock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _esReposicion
                      ? 'Stock actual + lo que traen los paquetes (− y + cambian los paquetes)'
                      : 'Nuevo stock',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _esReposicion
                          // En reposición el stock se calcula solo
                          ? InputDecorator(
                              decoration: _decoracion(relleno: Colors.white),
                              child: Text(
                                '$_stockResultante',
                                style: const TextStyle(fontSize: 17),
                              ),
                            )
                          : TextField(
                              controller: _stock,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(fontSize: 17),
                              decoration: _decoracion(relleno: Colors.white),
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
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Motivo del ajuste',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: _decoracion(relleno: const Color(0xFFF1F1F4)).copyWith(
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
                style: const TextStyle(fontSize: 17, color: Colors.black87),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9A9AA5)),
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
    final String texto;
    final Color color;
    final Color fondo;
    if (producto.agotado) {
      texto = 'Agotado';
      color = const Color(0xFFE53935);
      fondo = const Color(0xFFFDECEC);
    } else if (producto.stockBajo) {
      texto = 'Stock bajo';
      color = const Color(0xFFEF8A00);
      fondo = const Color(0xFFFFF3E0);
    } else {
      texto = 'En stock';
      color = const Color(0xFF22A559);
      fondo = const Color(0xFFE6F6EC);
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
              'Stock actual: ${producto.stock}/${producto.stockMaximo}',
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
