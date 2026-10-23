import 'package:flutter/foundation.dart';

import '../datos/productos_inventario_mock.dart';
import '../modelos/compra_inventario.dart';
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
  final List<CompraInventario> _compras = [];
  DateTime _ultimaActualizacion = DateTime.now();

  List<ProductoInventario> get productos => List.unmodifiable(_productos);
  List<ProductoInventario> get eliminados => List.unmodifiable(_eliminados);
  List<MovimientoInventario> get movimientos => List.unmodifiable(_movimientos);
  DateTime get ultimaActualizacion => _ultimaActualizacion;

  /// Todo lo que el hotel ha gastado en mercadería.
  List<CompraInventario> get compras => List.unmodifiable(_compras);

  /// Compras hechas desde el último cierre de caja.
  List<CompraInventario> get comprasDelTurno =>
      _compras.where((c) => c.enTurno).toList();

  /// Cuánto se ha gastado en inventario desde el último cierre de caja.
  double get gastoDelTurno => comprasDelTurno.fold(0.0, (s, c) => s + c.total);

  void _cambio() {
    _ultimaActualizacion = DateTime.now();
    notifyListeners();
  }

  String nuevoId() => 'inv-${DateTime.now().microsecondsSinceEpoch}';

  void _registrarCompra(
    ProductoInventario p, {
    required int paquetes,
    required int unidadesPorPaquete,
    required double costoPaquete,
    required bool esNuevo,
  }) {
    _compras.add(
      CompraInventario(
        id: 'cmp-${DateTime.now().microsecondsSinceEpoch}',
        productoId: p.id,
        producto: p.nombre,
        paquetes: paquetes,
        unidadesPorPaquete: unidadesPorPaquete,
        costoPaquete: costoPaquete,
        esNuevo: esNuevo,
        fecha: DateTime.now(),
      ),
    );
  }

  /// Agrega un producto nuevo. [paquetes] son los que se compraron para su
  /// stock inicial: ese gasto (paquetes × costo del paquete) queda registrado.
  void agregar(ProductoInventario producto, {int paquetes = 0}) {
    _productos.add(producto);
    if (paquetes > 0 && producto.costoPaquete > 0) {
      _registrarCompra(
        producto,
        paquetes: paquetes,
        unidadesPorPaquete: producto.unidadesPorPaquete,
        costoPaquete: producto.costoPaquete,
        esNuevo: true,
      );
    }
    _cambio();
  }

  /// Repone stock comprando paquetes. Sube el stock, guarda el gasto y, si
  /// [actualizarPrecio], recalcula el precio de venta (costo por unidad + 30%).
  /// Sirve cuando el paquete subió (o bajó) de precio.
  void reponerStock(
    String id, {
    required int paquetes,
    required int unidadesPorPaquete,
    required double costoPaquete,
    bool actualizarPrecio = true,
    String nota = '',
  }) {
    final i = _productos.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final unidades = paquetes * unidadesPorPaquete;
    if (unidades <= 0) return;

    final anterior = _productos[i];
    final nuevoStock = anterior.stock + unidades;
    final costoUnidad = unidadesPorPaquete > 0
        ? costoPaquete / unidadesPorPaquete
        : 0.0;
    final nuevoPrecio = (actualizarPrecio && costoUnidad > 0)
        ? precioDeVenta(costoUnidad)
        : anterior.precio;

    _productos[i] = anterior.copyWith(
      stock: nuevoStock,
      // Si lo comprado no cabe, el máximo sube para que no se pierda stock.
      stockMaximo: nuevoStock > anterior.stockMaximo ? nuevoStock : null,
      precio: nuevoPrecio,
      costoPaquete: costoPaquete,
      unidadesPorPaquete: unidadesPorPaquete,
    );
    _movimientos.add(
      MovimientoInventario(
        productoId: id,
        producto: anterior.nombre,
        stockAnterior: anterior.stock,
        stockNuevo: nuevoStock,
        motivo: 'Reposición de stock',
        nota: nota,
        fecha: DateTime.now(),
      ),
    );
    if (costoPaquete > 0) {
      _registrarCompra(
        anterior,
        paquetes: paquetes,
        unidadesPorPaquete: unidadesPorPaquete,
        costoPaquete: costoPaquete,
        esNuevo: false,
      );
    }
    _cambio();
  }

  /// Cambia el stock de un producto y guarda el movimiento (motivo y nota).
  /// Para comprar paquetes (con gasto y precio) se usa [reponerStock].
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

  /// Se llama al cerrar la caja: los gastos de inventario del turno quedan
  /// asignados a esa caja y el siguiente turno empieza en cero.
  void cerrarCompras(String numeroCaja) {
    for (var i = 0; i < _compras.length; i++) {
      if (_compras[i].enTurno) _compras[i] = _compras[i].cerrada(numeroCaja);
    }
    notifyListeners();
  }

  /// Revisa que alcance el stock para una venta. Devuelve el mensaje del
  /// primer problema, o null si todo está bien. Los artículos que no son del
  /// inventario (por ejemplo los servicios) se ignoran.
  String? verificarStock(List<({String id, int cantidad})> items) {
    for (final item in items) {
      final i = _productos.indexWhere((p) => p.id == item.id);
      if (i == -1) continue;
      final p = _productos[i];
      if (item.cantidad > p.stock) {
        return p.stock == 0
            ? '${p.nombre} está agotado'
            : 'Solo quedan ${p.stock} de ${p.nombre}';
      }
    }
    return null;
  }

  /// Baja el stock por una venta hecha en la tienda (busca por id).
  /// Guarda un movimiento con el motivo "Venta". Nunca baja de 0.
  void descontarVenta(List<({String id, int cantidad})> items) {
    var hubo = false;
    for (final item in items) {
      final i = _productos.indexWhere((p) => p.id == item.id);
      if (_descontar(i, item.cantidad)) hubo = true;
    }
    if (hubo) _cambio();
  }

  /// Igual que [descontarVenta], pero buscando por nombre (para los productos
  /// del catálogo rápido de "Nuevo huésped", que no traen id).
  void descontarPorNombre(List<({String nombre, int cantidad})> items) {
    var hubo = false;
    for (final item in items) {
      final i = _productos.indexWhere((p) => p.nombre == item.nombre);
      if (_descontar(i, item.cantidad)) hubo = true;
    }
    if (hubo) _cambio();
  }

  bool _descontar(int i, int cantidad) {
    if (i == -1) return false;
    final anterior = _productos[i];
    final nuevo = anterior.stock - cantidad < 0 ? 0 : anterior.stock - cantidad;
    if (nuevo == anterior.stock) return false;
    _productos[i] = anterior.copyWith(stock: nuevo);
    _movimientos.add(
      MovimientoInventario(
        productoId: anterior.id,
        producto: anterior.nombre,
        stockAnterior: anterior.stock,
        stockNuevo: nuevo,
        motivo: 'Venta',
        nota: '',
        fecha: DateTime.now(),
      ),
    );
    return true;
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
