import 'package:flutter/material.dart';

import '../modelos/articulo_tienda.dart';
import 'tarjeta_articulo.dart';

/// Encabezado (icono + título + flecha) y cuadrícula de 2 columnas.
class SeccionArticulos extends StatelessWidget {
  final SeccionTienda seccion;
  final List<ArticuloTienda> articulos;
  final void Function(ArticuloTienda) onAgregar;
  final VoidCallback? onVerTodo;

  const SeccionArticulos({
    super.key,
    required this.seccion,
    required this.articulos,
    required this.onAgregar,
    this.onVerTodo,
  });

  static const _iconos = <SeccionTienda, IconData>{
    SeccionTienda.habitaciones: Icons.bed_outlined,
    SeccionTienda.servicio: Icons.room_service_outlined,
    SeccionTienda.productos: Icons.shopping_bag_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onVerTodo,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(_iconos[seccion], size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    seccion.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 28),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articulos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) => TarjetaArticulo(
            articulo: articulos[i],
            onAgregar: () => onAgregar(articulos[i]),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
