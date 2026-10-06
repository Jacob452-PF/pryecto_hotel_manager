class ProductoTienda {
  final String id;
  final String nombre;
  final double precio;

  /// Sección donde se muestra: 'Habitaciones', 'Servicio', 'Productos del hotel'.
  final String seccion;

  /// Categoría del filtro: 'Alimentos', 'Bebidas', 'Aseo', 'Lencería', 'Otros'.
  final String categoria;

  const ProductoTienda({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.seccion,
    required this.categoria,
  });
}

/// Datos de prueba. Luego los puedes reemplazar por tu base de datos (carpeta datos/).
const productosDemo = <ProductoTienda>[
  ProductoTienda(
    id: 'h1',
    nombre: 'Habitación familiar',
    precio: 20,
    seccion: 'Habitaciones',
    categoria: 'Otros',
  ),
  ProductoTienda(
    id: 'h2',
    nombre: 'Habitación matrimonial',
    precio: 20,
    seccion: 'Habitaciones',
    categoria: 'Otros',
  ),
  ProductoTienda(
    id: 's1',
    nombre: 'Limpieza',
    precio: 20,
    seccion: 'Servicio',
    categoria: 'Aseo',
  ),
  ProductoTienda(
    id: 's2',
    nombre: 'Servicio de lavandería',
    precio: 20,
    seccion: 'Servicio',
    categoria: 'Lencería',
  ),
  ProductoTienda(
    id: 'p1',
    nombre: 'Agua purificada',
    precio: 20,
    seccion: 'Productos del hotel',
    categoria: 'Bebidas',
  ),
  ProductoTienda(
    id: 'p2',
    nombre: 'Coca cola',
    precio: 20,
    seccion: 'Productos del hotel',
    categoria: 'Bebidas',
  ),
];
