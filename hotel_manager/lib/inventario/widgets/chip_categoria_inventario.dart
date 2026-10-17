import 'package:flutter/material.dart';

import '../modelos/producto_inventario.dart';

/// Filtro de categoría (Todos, Alimentos, Bebidas, Aseo, Lencería, Otros).
class ChipCategoriaInventario extends StatelessWidget {
  final CategoriaInventario categoria;
  final bool seleccionada;
  final VoidCallback onTap;

  const ChipCategoriaInventario({
    super.key,
    required this.categoria,
    required this.seleccionada,
    required this.onTap,
  });

  static const _iconos = <CategoriaInventario, IconData>{
    CategoriaInventario.todos: Icons.grid_view_rounded,
    CategoriaInventario.alimentos: Icons.restaurant,
    CategoriaInventario.bebidas: Icons.wine_bar,
    CategoriaInventario.aseo: Icons.cleaning_services,

    CategoriaInventario.otros: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: seleccionada
                ? const Color(0xFF9FD8DC)
                : const Color(0xFFCDEBEC),
            borderRadius: BorderRadius.circular(10),
            border: seleccionada
                ? Border.all(color: const Color(0xFF1E56A8), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconos[categoria], size: 26, color: Colors.black87),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  categoria.etiqueta,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
