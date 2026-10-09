import 'package:flutter/material.dart';

import '../modelos/producto.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';

/// Catálogo rápido de productos del hotel. Si no hay productos, muestra un aviso.
class CatalogoRapido extends StatelessWidget {
  final List<Producto> productos;
  final ValueChanged<Producto> alAgregar;

  const CatalogoRapido({
    super.key,
    required this.productos,
    required this.alAgregar,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 40,
                color: ColoresApp.textoSecundario,
              ),
              SizedBox(height: 8),
              Text('Aún no hay productos', style: EstilosTexto.textoVacio),
              Text(
                'Aparecerán aquí cuando se agreguen',
                style: EstilosTexto.textoVacio,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: productos
          .map(
            (producto) => ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(
                '${producto.nombre} · ${formatearDinero(producto.precio)}',
              ),
              onPressed: () => alAgregar(producto),
            ),
          )
          .toList(),
    );
  }
}
