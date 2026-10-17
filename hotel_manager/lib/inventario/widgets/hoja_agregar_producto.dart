import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../servicios/servicio_inventario.dart';
import '../modelos/producto_inventario.dart';

/// Hoja inferior para agregar un producto nuevo.
Future<void> mostrarAgregarProducto(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _HojaAgregarProducto(),
  );
}

class _HojaAgregarProducto extends StatefulWidget {
  const _HojaAgregarProducto();

  @override
  State<_HojaAgregarProducto> createState() => _EstadoHojaAgregar();
}

class _EstadoHojaAgregar extends State<_HojaAgregarProducto> {
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _maximo = TextEditingController(text: '50');
  CategoriaInventario _categoria = CategoriaInventario.alimentos;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    _maximo.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    final precio = double.tryParse(_precio.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_stock.text.trim());
    final maximo = int.tryParse(_maximo.text.trim());

    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre del producto.');
      return;
    }
    if (precio == null || precio < 0) {
      setState(() => _error = 'Escribe un precio válido.');
      return;
    }
    if (stock == null || maximo == null || maximo < 1) {
      setState(() => _error = 'Revisa el stock actual y el máximo.');
      return;
    }
    if (stock > maximo) {
      setState(() => _error = 'El stock actual no puede superar el máximo.');
      return;
    }

    final servicio = ServicioInventario.instancia;
    servicio.agregar(
      ProductoInventario(
        id: servicio.nuevoId(),
        nombre: nombre,
        precio: precio,
        categoria: _categoria,
        stock: stock,
        stockMaximo: maximo,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = CategoriaInventario.values.where(
      (c) => c != CategoriaInventario.todos,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar producto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precio,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Categoría', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c in categorias)
                  ChoiceChip(
                    label: Text(c.etiqueta),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maximo,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock máximo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFE53935))),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
