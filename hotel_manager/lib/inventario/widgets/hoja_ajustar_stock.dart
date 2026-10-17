import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../servicios/servicio_inventario.dart';
import '../modelos/producto_inventario.dart';

/// Hoja inferior para cambiar el stock actual y el máximo de un producto.
Future<void> mostrarAjustarStock(
  BuildContext context,
  ProductoInventario producto,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaAjustarStock(producto: producto),
  );
}

class _HojaAjustarStock extends StatefulWidget {
  final ProductoInventario producto;
  const _HojaAjustarStock({required this.producto});

  @override
  State<_HojaAjustarStock> createState() => _EstadoHojaAjustar();
}

class _EstadoHojaAjustar extends State<_HojaAjustarStock> {
  late final TextEditingController _stock = TextEditingController(
    text: '${widget.producto.stock}',
  );
  late final TextEditingController _maximo = TextEditingController(
    text: '${widget.producto.stockMaximo}',
  );
  String? _error;

  @override
  void dispose() {
    _stock.dispose();
    _maximo.dispose();
    super.dispose();
  }

  void _sumar(int delta) {
    final actual = int.tryParse(_stock.text.trim()) ?? 0;
    final nuevo = actual + delta < 0 ? 0 : actual + delta;
    setState(() {
      _stock.text = '$nuevo';
      _error = null;
    });
  }

  void _guardar() {
    final stock = int.tryParse(_stock.text.trim());
    final maximo = int.tryParse(_maximo.text.trim());
    if (stock == null || maximo == null) {
      setState(() => _error = 'Escribe números válidos.');
      return;
    }
    if (maximo < 1) {
      setState(() => _error = 'El stock máximo debe ser al menos 1.');
      return;
    }
    if (stock > maximo) {
      setState(() => _error = 'El stock actual no puede superar el máximo.');
      return;
    }
    ServicioInventario.instancia.actualizarStock(
      widget.producto.id,
      stock: stock,
      stockMaximo: maximo,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
              'Ajustar stock',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.producto.nombre,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => _sumar(-1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _sumar(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maximo,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Stock máximo',
                border: OutlineInputBorder(),
              ),
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
