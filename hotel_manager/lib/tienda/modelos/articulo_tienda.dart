/// Categorías para los filtros de la parte superior.
enum CategoriaTienda {
  todos('Todos'),
  alimentos('Alimentos'),
  bebidas('Bebidas'),
  aseo('Aseo'),
  lenceria('Lencería');

  final String etiqueta;
  const CategoriaTienda(this.etiqueta);
}

/// Secciones en las que se agrupa la pantalla.
enum SeccionTienda {
  habitaciones('Habitaciones'),
  servicio('Servicio'),
  productos('Productos del hotel');

  final String titulo;
  const SeccionTienda(this.titulo);
}

/// Artículo que se muestra en la tienda (habitación, servicio o producto).
/// Cuando tengan base de datos, solo agreguen fromJson/toJson aquí.
class ArticuloTienda {
  final String id;
  final String nombre;
  final double precio;
  final SeccionTienda seccion;
  final CategoriaTienda? categoria;
  final String? imagen; // ruta de asset (opcional por ahora)

  const ArticuloTienda({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.seccion,
    this.categoria,
    this.imagen,
  });
}
