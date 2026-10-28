import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import 'dialogo_inventario.dart';

/// Ventana "Agregar producto". Se escribe lo que cuesta el PAQUETE y cuántos
/// paquetes se compraron: el precio de venta de cada unidad sale solo
/// (costo por unidad + 30%) y el gasto queda en Inventario y Cierre de caja.
Future<void> mostrarAgregarProducto(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _DialogoAgregar(),
  );
}

class _DialogoAgregar extends StatefulWidget {
  const _DialogoAgregar();

  @override
  State<_DialogoAgregar> createState() => _EstadoDialogoAgregar();
}

class _EstadoDialogoAgregar extends State<_DialogoAgregar> {
  final _nombre = TextEditingController();
  final _costoPaquete = TextEditingController();
  final _paquetes = TextEditingController(text: '1');
  final _unidades = TextEditingController(text: '1');
  final _maximo = TextEditingController(text: '50');
  CategoriaInventario _categoria = CategoriaInventario.alimentos;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _costoPaquete.dispose();
    _paquetes.dispose();
    _unidades.dispose();
    _maximo.dispose();
    super.dispose();
  }

  double? _leerDinero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  int get _numPaquetes => int.tryParse(_paquetes.text.trim()) ?? 0;
  int get _numUnidades => int.tryParse(_unidades.text.trim()) ?? 0;
  double? get _costo => _leerDinero(_costoPaquete.text);

  String _d(double v) => '\$${v.toStringAsFixed(2)}';

  InputDecoration _decoracion(
    String etiqueta, {
    String? prefijo,
    String? ayuda,
  }) {
    final colores = Theme.of(context).colorScheme;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colores.outline),
    );
    return InputDecoration(
      labelText: etiqueta,
      prefixText: prefijo,
      helperText: ayuda,
      helperMaxLines: 2,
      filled: true,
      fillColor: colores.surfaceContainerHighest,
      border: borde,
      enabledBorder: borde,
      labelStyle: TextStyle(color: colores.onSurfaceVariant),
      hintStyle: TextStyle(color: colores.onSurfaceVariant),
      helperStyle: TextStyle(color: colores.onSurfaceVariant),
      prefixStyle: TextStyle(color: colores.onSurface),
    );
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    final paquetes = _numPaquetes;
    final unidades = _numUnidades;
    final costo = _costo;

    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre del producto.');
      return;
    }
    if (costo == null || costo <= 0) {
      setState(() => _error = 'Escribe cuánto cuesta el paquete.');
      return;
    }
    if (paquetes < 1) {
      setState(() => _error = 'Escribe cuántos paquetes compraste.');
      return;
    }
    if (unidades < 1) {
      setState(() => _error = 'Escribe cuántas unidades trae cada paquete.');
      return;
    }

    final stock = paquetes * unidades;
    var maximo = int.tryParse(_maximo.text.trim()) ?? 50;
    if (maximo < stock) maximo = stock; // el máximo nunca es menor al stock

    final servicio = ServicioInventario.instancia;
    servicio.agregar(
      ProductoInventario(
        id: servicio.nuevoId(),
        nombre: nombre,
        precio: precioDeVenta(costo / unidades), // costo por unidad + 30%
        categoria: _categoria,
        stock: stock,
        stockMaximo: maximo,
        unidadesPorPaquete: unidades,
        costoPaquete: costo,
      ),
      paquetes: paquetes,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final categorias = CategoriaInventario.values.where(
      (c) => c != CategoriaInventario.todos,
    );

    final costo = _costo ?? 0.0;
    final unidades = _numUnidades;
    final paquetes = _numPaquetes;
    final hayDatos = costo > 0 && unidades > 0;
    final costoUnidad = hayDatos ? costo / unidades : 0.0;

    return DialogoInventario(
      icono: Icons.add_box_outlined,
      titulo: 'Agregar producto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoracion('Nombre'),
          ),
          const SizedBox(height: 16),
          Text(
            'Categoría',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colores.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in categorias)
                ChoiceChip(
                  label: Text(c.etiqueta),
                  selected: _categoria == c,
                  onSelected: (_) => setState(() => _categoria = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Compra del paquete',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colores.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _costoPaquete,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _decoracion(
              'Costo del paquete',
              prefijo: '\$ ',
              ayuda: 'Lo que le costó al hotel cada paquete.',
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
                  decoration: _decoracion('Paquetes comprados'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unidades,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: _decoracion('Unidades por paquete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maximo,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoracion('Stock máximo'),
          ),
          const SizedBox(height: 14),
          // Cuentas automáticas
          ResumenCompra(
            filas: [
              FilaResumen('Unidades que entran', '${paquetes * unidades}'),
              FilaResumen('Costo por unidad', hayDatos ? _d(costoUnidad) : '—'),
              FilaResumen(
                'Gasto total ($paquetes × ${costo > 0 ? _d(costo) : '—'})',
                hayDatos ? _d(paquetes * costo) : '—',
              ),
              FilaResumen(
                'Precio de venta por unidad (+20%)',
                hayDatos ? _d(precioDeVenta(costoUnidad)) : '—',
                destacar: true,
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 20),
          BotonesDialogo(
            textoGuardar: 'Guardar',
            onGuardar: _guardar,
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
