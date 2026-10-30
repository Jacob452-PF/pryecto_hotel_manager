import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/compra_inventario.dart';
import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import 'dialogo_inventario.dart';

/// Ventana "Editar compra": sirve para corregir un error (por ejemplo, el
/// costo del paquete estaba mal escrito). El gasto se corrige y en Cierre de
/// caja queda anotado lo que se había registrado antes.
Future<void> mostrarEditarCompra(
  BuildContext context,
  CompraInventario compra,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoEditar(compra: compra),
  );
}

class _DialogoEditar extends StatefulWidget {
  final CompraInventario compra;
  const _DialogoEditar({required this.compra});

  @override
  State<_DialogoEditar> createState() => _EstadoDialogoEditar();
}

class _EstadoDialogoEditar extends State<_DialogoEditar> {
  late final TextEditingController _paquetes = TextEditingController(
    text: '${widget.compra.paquetes}',
  );
  late final TextEditingController _costo = TextEditingController(
    text: widget.compra.costoPaquete.toStringAsFixed(2),
  );
  bool _actualizarPrecio = true;
  String? _error;

  @override
  void dispose() {
    _paquetes.dispose();
    _costo.dispose();
    super.dispose();
  }

  int get _numPaquetes => int.tryParse(_paquetes.text.trim()) ?? 0;
  double? get _costoNuevo =>
      double.tryParse(_costo.text.trim().replaceAll(',', '.'));

  String _d(double v) => '\$${v.toStringAsFixed(2)}';

  InputDecoration _decoracion(String etiqueta, {String? prefijo}) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF9A9AA5)),
    );
    return InputDecoration(
      labelText: etiqueta,
      prefixText: prefijo,
      filled: true,
      fillColor: const Color(0xFFF6F6F9),
      border: borde,
      enabledBorder: borde,
    );
  }

  void _guardar() {
    final costo = _costoNuevo;
    if (_numPaquetes < 1) {
      setState(() => _error = 'Escribe cuántos paquetes se compraron.');
      return;
    }
    if (costo == null || costo < 0) {
      setState(() => _error = 'Escribe cuánto costó el paquete.');
      return;
    }
    ServicioInventario.instancia.editarCompra(
      widget.compra.id,
      paquetes: _numPaquetes,
      costoPaquete: costo,
      actualizarPrecio: _actualizarPrecio,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.compra;
    final costo = _costoNuevo ?? 0.0;
    final totalNuevo = _numPaquetes * costo;
    final diferencia = totalNuevo - c.total;
    final unidadesCambian = (_numPaquetes - c.paquetes) * c.unidadesPorPaquete;
    final esUltima = ServicioInventario.instancia.esUltimaCompra(c);
    final costoUnidad = c.unidadesPorPaquete > 0
        ? costo / c.unidadesPorPaquete
        : 0.0;

    return DialogoInventario(
      icono: Icons.edit_outlined,
      titulo: 'Editar compra',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.producto,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Text(
            '${c.esNuevo ? 'Producto nuevo' : 'Reposición'} · '
            '${c.unidadesPorPaquete} unidades por paquete',
            style: const TextStyle(fontSize: 13, color: Color(0xFF55555F)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _costo,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _decoracion('Costo del paquete', prefijo: '\$ '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _paquetes,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: _decoracion('Paquetes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResumenCompra(
            filas: [
              FilaResumen('Gasto registrado antes', _d(c.total)),
              FilaResumen('Gasto corregido', _d(totalNuevo), destacar: true),
              FilaResumen(
                'Diferencia',
                '${diferencia < 0 ? '−' : '+'}${_d(diferencia.abs())}',
              ),
              if (unidadesCambian != 0)
                FilaResumen(
                  'Stock del producto',
                  '${unidadesCambian > 0 ? '+' : '−'}${unidadesCambian.abs()} unidades',
                ),
              if (esUltima && costo > 0)
                FilaResumen(
                  'Precio de venta (+30%)',
                  _d(precioDeVenta(costoUnidad)),
                ),
            ],
          ),
          // Solo la compra más reciente cambia el costo/precio actual
          if (esUltima)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _actualizarPrecio,
              onChanged: (v) => setState(() => _actualizarPrecio = v),
              title: const Text(
                'Actualizar también el precio de venta del producto',
                style: TextStyle(fontSize: 13),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'La corrección quedará anotada en Cierre de caja, con lo que se había registrado antes.',
            style: TextStyle(fontSize: 12, color: Color(0xFF55555F)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 20),
          BotonesDialogo(
            textoGuardar: 'Guardar edición',
            onGuardar: _guardar,
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
