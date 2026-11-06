import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../inventario/modelos/producto_inventario.dart';
import '../widgets/selector_foto_producto.dart';

/// Lo que devuelve el formulario al guardar.
class DatosNuevoProducto {
  final String nombre;
  final CategoriaInventario categoria;
  final double precioVenta;
  final int paquetes;
  final int unidadesPorPaquete;
  final double costoPaquete;
  final int stockMaximo;
  final int stockMinimo;
  final Uint8List? foto;

  const DatosNuevoProducto({
    required this.nombre,
    required this.categoria,
    required this.precioVenta,
    required this.paquetes,
    required this.unidadesPorPaquete,
    required this.costoPaquete,
    required this.stockMaximo,
    required this.stockMinimo,
    this.foto,
  });
}

class PantallaAgregarProducto extends StatefulWidget {
  const PantallaAgregarProducto({super.key});

  @override
  State<PantallaAgregarProducto> createState() =>
      _EstadoPantallaAgregarProducto();
}

class _EstadoPantallaAgregarProducto extends State<PantallaAgregarProducto> {
  final _llave = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _paquetes = TextEditingController(text: '1');
  final _unidades = TextEditingController(text: '1');
  final _costo = TextEditingController();
  final _stockMaximo = TextEditingController(text: '50');
  final _stockMinimo = TextEditingController(text: '5');
  CategoriaInventario _categoria = CategoriaInventario.alimentos;
  Uint8List? _foto;

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _paquetes,
      _unidades,
      _costo,
      _stockMaximo,
      _stockMinimo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String t) => double.tryParse(t.replaceAll(',', '.'));

  String? _validaPositivo(String? t) {
    final n = _num(t ?? '');
    return (n == null || n <= 0) ? 'Escribe un número mayor a 0' : null;
  }

  String? _validaEntero(String? t) {
    final n = int.tryParse(t ?? '');
    return (n == null || n <= 0) ? 'Escribe un entero mayor a 0' : null;
  }

  double get _totalGasto =>
      (int.tryParse(_paquetes.text) ?? 0) * (_num(_costo.text) ?? 0);

  double get _costoUnidad {
    final u = int.tryParse(_unidades.text) ?? 0;
    return u > 0 ? (_num(_costo.text) ?? 0) / u : 0;
  }

  double get _precioVenta => (_costoUnidad * 1.2 * 100).round() / 100;

  void _guardar() {
    if (!_llave.currentState!.validate()) return;
    final stock = int.parse(_paquetes.text) * int.parse(_unidades.text);
    final maximo = int.tryParse(_stockMaximo.text) ?? 50;
    Navigator.pop(
      context,
      DatosNuevoProducto(
        nombre: _nombre.text.trim(),
        categoria: _categoria,
        precioVenta: _precioVenta,
        paquetes: int.parse(_paquetes.text),
        unidadesPorPaquete: int.parse(_unidades.text),
        costoPaquete: _num(_costo.text)!,
        stockMaximo: maximo < stock ? stock : maximo,
        stockMinimo: int.tryParse(_stockMinimo.text) ?? 5,
        foto: _foto,
      ),
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController c, {
    String? Function(String?)? validar,
    TextInputType? teclado,
    String? prefijo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validar,
        keyboardType: teclado,
        onChanged: (_) => setState(() {}), // actualiza el resumen
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixText: prefijo,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: Form(
        key: _llave,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SelectorFotoProducto(
              foto: _foto,
              onCambio: (f) => setState(() => _foto = f),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final categoria in CategoriaInventario.values)
                  if (categoria != CategoriaInventario.todos)
                    ChoiceChip(
                      label: Text(categoria.etiqueta),
                      selected: _categoria == categoria,
                      onSelected: (_) => setState(() => _categoria = categoria),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            _campo(
              'Nombre',
              _nombre,
              validar: (t) =>
                  (t == null || t.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Precio de venta (+20%)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              child: Text(_precioVenta.toStringAsFixed(2)),
            ),
            const SizedBox(height: 12),
            _campo(
              'Paquetes comprados',
              _paquetes,
              validar: _validaEntero,
              teclado: TextInputType.number,
            ),
            _campo(
              'Unidades por paquete',
              _unidades,
              validar: _validaEntero,
              teclado: TextInputType.number,
            ),
            _campo(
              'Costo de cada paquete',
              _costo,
              validar: _validaPositivo,
              teclado: decimal,
              prefijo: '\$',
            ),
            _campo(
              'Stock máximo',
              _stockMaximo,
              validar: _validaEntero,
              teclado: TextInputType.number,
            ),
            _campo(
              'Stock mínimo para aviso',
              _stockMinimo,
              validar: _validaEntero,
              teclado: TextInputType.number,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Gasto total: \$${_totalGasto.toStringAsFixed(2)}   ·   Costo por unidad: \$${_costoUnidad.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardar,
              child: const Text('Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
