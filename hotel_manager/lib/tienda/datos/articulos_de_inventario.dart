import '../../inventario/modelos/producto_inventario.dart';
import '../../inventario/servicios/servicio_inventario.dart';
import '../modelos/articulo_tienda.dart';
import 'articulos_mock.dart';

/// Todo lo que se muestra en la tienda:
///  - los servicios (Limpieza, etc.) que siguen en `articulos_mock.dart`
///  - los PRODUCTOS, que vienen del inventario (los que ya estaban y los
///    que se agreguen después; los eliminados desaparecen de la tienda).
List<ArticuloTienda> articulosDeTienda() {
  final delInventario = ServicioInventario.instancia.productos
      .map(_aArticulo)
      .toList();

  // Los productos escritos a mano en articulos_mock.dart ya no se usan.
  final otros = articulosMock.where(
    (a) => a.seccion != SeccionTienda.productos,
  );

  return [...otros, ...delInventario];
}

ArticuloTienda _aArticulo(ProductoInventario p) {
  return ArticuloTienda(
    id: p.id,
    nombre: p.nombre,
    precio: p.precio,
    seccion: SeccionTienda.productos,
    categoria: _categoriaDeTienda(p.categoria),
    imagen: p.imagen,
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
