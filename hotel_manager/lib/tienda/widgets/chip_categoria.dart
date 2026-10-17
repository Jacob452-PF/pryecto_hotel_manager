import 'package:flutter/material.dart';

import '../modelos/articulo_tienda.dart';

/// Filtro de categoría (Todos, Alimentos, Bebidas, Aseo, Lencería).
class ChipCategoria extends StatelessWidget {
  final CategoriaTienda categoria;
  final bool seleccionada;
  final VoidCallback onTap;

  const ChipCategoria({
    super.key,
    required this.categoria,
    required this.seleccionada,
    required this.onTap,
  });

  static const _iconos = <CategoriaTienda, IconData>{
    CategoriaTienda.todos: Icons.grid_view_rounded,
    CategoriaTienda.alimentos: Icons.restaurant,
    CategoriaTienda.bebidas: Icons.wine_bar,
    CategoriaTienda.aseo: Icons.cleaning_services,
  };

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: seleccionada ? colores.secondaryContainer : colores.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: seleccionada
                ? Border.all(color: colores.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconos[categoria], size: 26, color: colores.onSurface),
              const SizedBox(height: 4),
              Text(
                categoria.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colores.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
