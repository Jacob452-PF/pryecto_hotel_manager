import 'package:flutter/material.dart';

import '../modelos/articulo_tienda.dart';

/// Tarjeta de un artículo: imagen, nombre, precio y botón de agregar.
class TarjetaArticulo extends StatelessWidget {
  final ArticuloTienda articulo;
  final VoidCallback onAgregar;

  const TarjetaArticulo({
    super.key,
    required this.articulo,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFD9D9D9),
                child: articulo.imagen == null
                    ? null
                    : Image.asset(
                        articulo.imagen!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            articulo.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${articulo.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAgregar,
                tooltip: 'Agregar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
