import 'package:flutter/foundation.dart';

import '../datos/productos_inventario_mock.dart';
import '../modelos/movimiento_inventario.dart';
import '../modelos/producto_inventario.dart';

/// Guarda los productos del inventario y avisa a la pantalla cuando cambian.
/// Vive en memoria; cuando haya base de datos, solo se cambia este archivo.
class ServicioInventario extends ChangeNotifier {
  ServicioInventario._();

  static final ServicioInventario instancia = ServicioInventario._();

  final List<ProductoInventario> _productos = List.of(productosInventarioMock);
  final List<ProductoInventario> _eliminados = [];
  final List<MovimientoInventario> _movimientos = [];
  DateTime _ultimaActualizacion = DateTime.now();

  List<ProductoInventario> get productos => List.unmodifiable(_productos);
  List<ProductoInventario> get eliminados => List.unmodifiable(_eliminados);
  List<MovimientoInventario> get movimientos => List.unmodifiable(_movimientos);
  DateTime get ultimaActualizacion => _ultimaActualizacion;

  void _cambio() {
    _ultimaActualizacion = DateTime.now();
    notifyListeners();
  }

  String nuevoId() => 'inv-${DateTime.now().microsecondsSinceEpoch}';

  void agregar(ProductoInventario producto) {
    _productos.add(producto);
    _cambio();
  }

  /// Cambia el stock de un producto y guarda el movimiento (motivo y nota).
  /// Si no se indica [stockMaximo], se conserva el que ya tenía.
  void actualizarStock(
    String id, {
    required int stock,
    int? stockMaximo,
    String motivo = '',
    String nota = '',
  }) {
    final i = _productos.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final anterior = _productos[i];
    _productos[i] = anterior.copyWith(stock: stock, stockMaximo: stockMaximo);
    if (stock != anterior.stock) {
      _movimientos.add(
        MovimientoInventario(
          productoId: id,
          producto: anterior.nombre,
          stockAnterior: anterior.stock,
          stockNuevo: stock,
          motivo: motivo,
          nota: nota,
          fecha: DateTime.now(),
        ),
      );
    }
    _cambio();
  }

  void eliminar(String id) {
    final i = _productos.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _eliminados.add(_productos.removeAt(i));
    _cambio();
  }

  void restaurar(String id) {
    final i = _eliminados.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _productos.add(_eliminados.removeAt(i));
    _cambio();
  }
}
