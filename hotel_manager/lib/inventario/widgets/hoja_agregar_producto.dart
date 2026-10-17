import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import 'dialogo_inventario.dart';

/// Ventana "Agregar producto" (mismo estilo que "Ajustar producto").
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
          const SizedBox(height: 12),
          TextField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: _decoracion('Precio', prefijo: '\$ '),
          ),
          const SizedBox(height: 16),
          const Text(
            'Categoría',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoracion('Stock actual'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maximo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoracion('Stock máximo'),
                ),
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
