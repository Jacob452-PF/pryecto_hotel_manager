import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/producto_inventario.dart';
import '../servicios/servicio_inventario.dart';
import 'dialogo_inventario.dart';
import 'fila_producto_inventario.dart';

/// Ventana "Ajustar producto": nuevo stock, motivo del ajuste y nota.
Future<void> mostrarAjustarStock(
  BuildContext context,
  ProductoInventario producto,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogoAjustar(producto: producto),
  );
}

const _motivos = [
  'Merma',
  'Reposición de stock',
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
  String _motivo = _motivos.first;
  String? _error;

  @override
  void dispose() {
    _stock.dispose();
    _nota.dispose();
    super.dispose();
  }

  void _sumar(int delta) {
    var nuevo = (int.tryParse(_stock.text.trim()) ?? 0) + delta;
    if (nuevo < 0) nuevo = 0;
    if (nuevo > widget.producto.stockMaximo) {
      nuevo = widget.producto.stockMaximo;
    }
    setState(() {
      _stock.text = '$nuevo';
      _error = null;
    });
  }

  void _guardar() {
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null) {
      setState(() => _error = 'Escribe un número válido.');
      return;
    }
    if (stock > widget.producto.stockMaximo) {
      setState(
        () => _error =
            'No puede superar el stock máximo (${widget.producto.stockMaximo}).',
      );
      return;
    }
    ServicioInventario.instancia.actualizarStock(
      widget.producto.id,
      stock: stock,
      motivo: _motivo,
      nota: _nota.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final colores = Theme.of(context).colorScheme;

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
              color: colores.surfaceContainerHighest,
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
                            'Precio: \$${p.precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colores.onSurfaceVariant,
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
                const Text('Nuevo stock', style: TextStyle(fontSize: 14)),
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colores.surface,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
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
            decoration: InputDecoration(
              filled: true,
              fillColor: colores.surfaceContainerHighest,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _motivo,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(fontSize: 17, color: colores.onSurface),
                items: [
                  for (final m in _motivos)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => _motivo = v ?? _motivo),
              ),
            ),
          ),
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
            decoration: InputDecoration(
              hintText: 'Añade una nota sobre el ajuste...',
              filled: true,
              fillColor: colores.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
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
      fondo = color.withValues(alpha: 0.14);
    } else if (producto.stockBajo) {
      texto = 'Stock bajo';
      color = const Color(0xFFEF8A00);
      fondo = color.withValues(alpha: 0.14);
    } else {
      texto = 'En stock';
      color = const Color(0xFF22A559);
      fondo = color.withValues(alpha: 0.14);
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
