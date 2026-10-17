/// Categorías del inventario (filtros de la parte superior).
enum CategoriaInventario {
  todos('Todos'),
  alimentos('Alimentos'),
  bebidas('Bebidas'),
  aseo('Aseo'),

  otros('Otros');

  final String etiqueta;
  const CategoriaInventario(this.etiqueta);
}

/// Producto del inventario con su stock.
/// Cuando tengan base de datos, solo agreguen fromJson/toJson aquí.
class ProductoInventario {
  final String id;
  final String nombre;
  final double precio;
  final CategoriaInventario categoria;
  final int stock;
  final int stockMaximo;
  final String? imagen; // ruta de asset (opcional por ahora)

  const ProductoInventario({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.stock,
    this.stockMaximo = 50,
    this.imagen,
  });

  bool get agotado => stock <= 0;

  /// Stock bajo: 20% o menos del máximo (incluye agotado).
  bool get stockBajo => stock <= stockMaximo * 0.2;

  ProductoInventario copyWith({int? stock, int? stockMaximo}) {
    return ProductoInventario(
      id: id,
      nombre: nombre,
      precio: precio,
      categoria: categoria,
      stock: stock ?? this.stock,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      imagen: imagen,
    );
  }
}
