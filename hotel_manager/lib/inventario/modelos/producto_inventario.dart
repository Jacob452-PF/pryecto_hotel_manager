import '../../servicios/servicio_configuracion.dart';

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

/// Ganancia que el hotel se queda sobre el costo de cada unidad (30%).
/// Para cambiarla, solo se modifica este número.
double get margenGanancia =>
    ServicioConfiguracion.instancia.valor.margenGananciaProducto;

/// Precio de venta de UNA unidad: su costo + la ganancia (30%).
/// Ejemplo: costo $1.00 → precio $1.30.
double precioDeVenta(double costoUnitario) =>
    (costoUnitario * (1 + margenGanancia) * 100).round() / 100;

/// Producto del inventario con su stock.
/// Cuando tengan base de datos, solo agreguen fromJson/toJson aquí.
class ProductoInventario {
  final String id;
  final String nombre;

  /// Precio de venta de una unidad (costo por unidad + 30%).
  final double precio;
  final CategoriaInventario categoria;
  final int stock;
  final int stockMaximo;
  final int stockMinimo;
  final String? imagen; // ruta de asset (opcional por ahora)

  /// Cuántas unidades trae cada paquete que compra el hotel.
  final int unidadesPorPaquete;

  /// Lo que cuesta cada paquete (0 si no se sabe).
  final double costoPaquete;

  const ProductoInventario({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoria,
    required this.stock,
    this.stockMaximo = 50,
    this.stockMinimo = 5,
    this.imagen,
    this.unidadesPorPaquete = 1,
    this.costoPaquete = 0,
  });

  /// Lo que le cuesta al hotel cada unidad: costo del paquete ÷ unidades.
  double get costoUnitario =>
      unidadesPorPaquete > 0 ? costoPaquete / unidadesPorPaquete : 0;

  bool get agotado => stock <= 0;

  /// El aviso de stock bajo usa el umbral explícito del producto.
  bool get stockBajo => stock <= stockMinimo;

  ProductoInventario copyWith({
    int? stock,
    int? stockMaximo,
    int? stockMinimo,
    double? precio,
    double? costoPaquete,
    int? unidadesPorPaquete,
  }) {
    return ProductoInventario(
      id: id,
      nombre: nombre,
      precio: precio ?? this.precio,
      categoria: categoria,
      stock: stock ?? this.stock,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      imagen: imagen,
      unidadesPorPaquete: unidadesPorPaquete ?? this.unidadesPorPaquete,
      costoPaquete: costoPaquete ?? this.costoPaquete,
    );
  }
}
