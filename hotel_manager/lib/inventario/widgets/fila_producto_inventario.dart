import 'package:flutter/material.dart';

import '../modelos/producto_inventario.dart';

/// Fila del listado: imagen, nombre, precio, stock, estado y botones.
class FilaProductoInventario extends StatelessWidget {
  final ProductoInventario producto;
  final VoidCallback onAjustar;
  final VoidCallback onEliminar;

  const FilaProductoInventario({
    super.key,
    required this.producto,
    required this.onAjustar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          MiniaturaProducto(imagen: producto.imagen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${producto.precio.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Stock
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Stock actual', style: TextStyle(fontSize: 9)),
              Text(
                '${producto.stock} /${producto.stockMaximo}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              _EstadoStock(producto: producto),
            ],
          ),
          const SizedBox(width: 8),
          // Ajustar
          Material(
            color: colores.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onAjustar,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                children: [
                    Icon(Icons.add_circle, size: 16, color: colores.primary),
                    SizedBox(width: 4),
                    Text(
                      'Ajustar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Eliminar
          Material(
            color: const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onEliminar,
              borderRadius: BorderRadius.circular(12),
              child: Tooltip(
                message: 'Eliminar',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3B5B5)),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadro gris de la imagen del producto (o su foto cuando exista).
class MiniaturaProducto extends StatelessWidget {
  final String? imagen;
  final double tamano;

  const MiniaturaProducto({super.key, this.imagen, this.tamano = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagen == null
          ? null
          : Image.asset(
              imagen!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
    );
  }
}

class _EstadoStock extends StatelessWidget {
  final ProductoInventario producto;
  const _EstadoStock({required this.producto});

  @override
  Widget build(BuildContext context) {
    final String texto;
    final Color color;
    if (producto.agotado) {
      texto = 'Agotado';
      color = const Color(0xFFE53935);
    } else if (producto.stockBajo) {
      texto = 'Stock bajo';
      color = const Color(0xFFEF8A00);
    } else {
      texto = 'En stock';
      color = Theme.of(context).colorScheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color == Theme.of(context).colorScheme.primary ? Theme.of(context).dividerColor : color),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
