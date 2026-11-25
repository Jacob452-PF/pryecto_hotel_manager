import '../../inventario/servicios/servicio_inventario.dart';
import '../modelos/articulo_tienda.dart';

/// Solo productos activos y disponibles del catálogo remoto.
List<ArticuloTienda> articulosDeTienda() {
  final delInventario = ServicioInventario.instancia.productos
      .where((p) => !p.agotado) // sin stock no se vende
      .map(_aArticulo)
      .toList();
  return delInventario;
}

ArticuloTienda _aArticulo(ProductoInventario p) {
  return ArticuloTienda(
    id: p.id,
    nombre: p.nombre,
    precio: p.precio,
    seccion: SeccionTienda.productos,
    categoria: _categoriaDeTienda(p.categoria),
    imagen: p.imagen,
    imagenBytes: p.imagenBytes,
  );
}

/// Busca la categoría de la tienda con el mismo nombre. Si no existe
/// (por ejemplo "Otros"), el producto se ve solo en "Todos".
CategoriaTienda? _categoriaDeTienda(CategoriaInventario c) {
  for (final t in CategoriaTienda.values) {
    if (t != CategoriaTienda.todos && t.name == c.name) return t;
  }
  return null;
}
