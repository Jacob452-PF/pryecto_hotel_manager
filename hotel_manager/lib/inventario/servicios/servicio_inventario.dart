import 'package:flutter/foundation.dart';

import '../../servicios/api_client.dart';
import '../modelos/compra_inventario.dart';
import '../modelos/movimiento_inventario.dart';
import '../modelos/producto_inventario.dart';

/// Lee el inventario compartido del API y conserva temporalmente los cambios
/// recibidos en memoria para que las pantallas se actualicen.
class ServicioInventario extends ChangeNotifier {
  ServicioInventario._();

  static final ServicioInventario instancia = ServicioInventario._();

  final List<ProductoInventario> _productos = [];
  final List<ProductoInventario> _eliminados = [];
  final List<MovimientoInventario> _movimientos = [];
  final List<CompraInventario> _compras = [];
  final Map<CategoriaInventario, int> _categoriasApi = {};
  DateTime _ultimaActualizacion = DateTime.now();
  String? error;
  bool cargando = false;

  List<ProductoInventario> get productos => List.unmodifiable(_productos);
  List<ProductoInventario> get eliminados => List.unmodifiable(_eliminados);
  List<MovimientoInventario> get movimientos => List.unmodifiable(_movimientos);
  DateTime get ultimaActualizacion => _ultimaActualizacion;

  Future<void> sincronizar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        ApiClient.instance.products(),
        ApiClient.instance.categories(),
      ]);
      final products = responses[0];
      final categories = responses[1];
      _categoriasApi.clear();
      for (final raw in categories) {
        if (raw is! Map) continue;
        final category = Map<String, dynamic>.from(raw);
        final id = int.tryParse(category['id']?.toString() ?? '');
        if (id == null) continue;
        final value = (category['name'] ?? '').toString().trim().toLowerCase();
        final local = switch (value) {
          'alimentos' || 'alimento' || 'food' => CategoriaInventario.alimentos,
          'bebidas' || 'bebida' || 'drinks' => CategoriaInventario.bebidas,
          'aseo' || 'limpieza' || 'cleaning' => CategoriaInventario.aseo,
          _ => CategoriaInventario.otros,
        };
        _categoriasApi.putIfAbsent(local, () => id);
      }
      _productos
        ..clear()
        ..addAll(
          products.where((p) => p.active).map((p) {
            final category = switch ((p.category ?? '').trim().toLowerCase()) {
              'alimentos' ||
              'alimento' ||
              'food' => CategoriaInventario.alimentos,
              'bebidas' || 'bebida' || 'drinks' => CategoriaInventario.bebidas,
              'aseo' || 'limpieza' || 'cleaning' => CategoriaInventario.aseo,
              _ => CategoriaInventario.otros,
            };
            return ProductoInventario(
              id: p.id.toString(),
              nombre: p.name,
              precio: p.price,
              categoria: category,
              categoriaIdApi: p.categoryId,
              stock: p.stock,
              stockMinimo: p.minStock,
            );
          }),
        );
      _ultimaActualizacion = DateTime.now();
    } on Object catch (e) {
      _productos.clear();
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> crearProductoRemoto(
    ProductoInventario producto, {
    required int paquetes,
    required int unidadesPorPaquete,
    required double costoPaquete,
    int? proveedorId,
  }) async {
    final categoryId =
        producto.categoriaIdApi ?? _categoriasApi[producto.categoria];
    if (categoryId == null) {
      throw StateError('La categoría no existe en el catálogo del servidor.');
    }
    final created = await ApiClient.instance.createProduct({
      'category_id': categoryId,
      'name': producto.nombre,
      'price': producto.precio,
      'stock': 0,
      'min_stock': producto.stockMinimo,
    });
    final productId = int.parse(created['id'].toString());
    try {
      if (paquetes > 0) {
        await ApiClient.instance.createPurchase([
          {
            'product_id': productId,
            'quantity': paquetes * unidadesPorPaquete,
            'unit_cost': unidadesPorPaquete > 0
                ? costoPaquete / unidadesPorPaquete
                : costoPaquete,
          },
        ], supplierId: proveedorId);
      }
    } finally {
      await sincronizar();
    }
  }

  Future<void> desactivarRemoto(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) throw StateError('El producto no tiene ID de API.');
    await ApiClient.instance.deleteProduct(productId);
    await sincronizar();
  }

  Future<void> restaurarRemoto(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) throw StateError('El producto no tiene ID de API.');
    await ApiClient.instance.updateProduct(productId, {
      'active': true,
    }, partial: true);
    await sincronizar();
  }

  Future<void> actualizarStockRemoto(
    String id, {
    required int stock,
    required String motivo,
  }) async {
    final productId = int.tryParse(id);
    if (productId == null) throw StateError('El producto no tiene ID de API.');
    await ApiClient.instance.updateProduct(productId, {
      'stock': stock,
      'reason': motivo,
    }, partial: true);
    await sincronizar();
  }

  Future<void> reponerStockRemoto(
    String id, {
    required int cantidad,
    required double costoUnitario,
    double? precioVenta,
  }) async {
    final productId = int.tryParse(id);
    if (productId == null) throw StateError('El producto no tiene ID de API.');
    await ApiClient.instance.createPurchase([
      {
        'product_id': productId,
        'quantity': cantidad,
        'unit_cost': costoUnitario,
      },
    ]);
    if (precioVenta != null) {
      await ApiClient.instance.updateProduct(productId, {
        'price': precioVenta,
      }, partial: true);
    }
    await sincronizar();
  }

  /// Todo lo que el hotel ha gastado en mercadería.
  List<CompraInventario> get compras => List.unmodifiable(_compras);

  /// Compras hechas desde el último cierre de caja.
  List<CompraInventario> get comprasDelTurno =>
      _compras.where((c) => c.enTurno).toList();

  /// Cuánto se ha gastado en inventario desde el último cierre de caja.
  double get gastoDelTurno => comprasDelTurno.fold(0.0, (s, c) => s + c.total);

  /// Indica si [compra] es la compra más reciente de su producto.
  bool esUltimaCompra(CompraInventario compra) {
    final indice = _compras.lastIndexWhere(
      (c) =>
          c.productoId == compra.productoId &&
          c.tipo == TipoMovimientoCompra.compra,
    );
    return indice != -1 && _compras[indice].id == compra.id;
  }

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
    TipoMovimientoCompra tipo = TipoMovimientoCompra.compra,
    String descripcion = '',
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
        tipo: tipo,
        fecha: DateTime.now(),
        descripcion: descripcion,
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
        descripcion: 'Stock inicial del producto nuevo',
      );
    }
    _cambio();
  }

  /// Repone stock comprando unidades y registra su gasto.
  void reponerStock(
    String id, {
    required int paquetes,
    required int unidadesPorPaquete,
    required double costoPaquete,
    bool actualizarPrecio = true,
    double? precioVenta,
    String nota = '',
  }) {
    if (paquetes < 1 ||
        unidadesPorPaquete < 1 ||
        !costoPaquete.isFinite ||
        costoPaquete < 0 ||
        (precioVenta != null && (!precioVenta.isFinite || precioVenta < 0))) {
      return;
    }
    final i = _productos.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final unidades = paquetes * unidadesPorPaquete;
    if (unidades <= 0) return;

    final anterior = _productos[i];
    final nuevoStock = anterior.stock + unidades;
    final costoUnidad = unidadesPorPaquete > 0
        ? costoPaquete / unidadesPorPaquete
        : 0.0;
    final nuevoPrecio = actualizarPrecio
        ? precioVenta ?? precioDeVenta(costoUnidad)
        : anterior.precio;
    if (!nuevoPrecio.isFinite || nuevoPrecio < 0) return;

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
    _registrarCompra(
      anterior,
      paquetes: paquetes,
      unidadesPorPaquete: unidadesPorPaquete,
      costoPaquete: costoPaquete,
      esNuevo: false,
      descripcion: nota.isEmpty
          ? 'Reposición de stock'
          : 'Reposición de stock: $nota',
    );
    _cambio();
  }

  /// Registra una devolución y su efecto tanto en existencias como en caja.
  /// Las devoluciones de clientes vuelven al stock y son un reembolso;
  /// las devoluciones al proveedor salen del stock y reducen el gasto neto.
  bool registrarDevolucion(
    String id, {
    required int cantidad,
    required double precioUnitario,
    required bool deCliente,
    String nota = '',
  }) {
    final i = _productos.indexWhere((p) => p.id == id);
    if (i == -1 ||
        cantidad < 1 ||
        !precioUnitario.isFinite ||
        precioUnitario < 0) {
      return false;
    }

    final anterior = _productos[i];
    if (!deCliente && cantidad > anterior.stock) return false;
    final nuevoStock = deCliente
        ? anterior.stock + cantidad
        : anterior.stock - cantidad;
    _productos[i] = anterior.copyWith(
      stock: nuevoStock,
      stockMaximo: nuevoStock > anterior.stockMaximo ? nuevoStock : null,
    );
    _movimientos.add(
      MovimientoInventario(
        productoId: id,
        producto: anterior.nombre,
        stockAnterior: anterior.stock,
        stockNuevo: nuevoStock,
        motivo: deCliente ? 'Devolución de cliente' : 'Devolución a proveedor',
        nota: nota,
        fecha: DateTime.now(),
      ),
    );
    _registrarCompra(
      anterior,
      paquetes: cantidad,
      unidadesPorPaquete: 1,
      costoPaquete: precioUnitario,
      esNuevo: false,
      tipo: deCliente
          ? TipoMovimientoCompra.devolucionCliente
          : TipoMovimientoCompra.devolucionProveedor,
      descripcion: nota,
    );
    _cambio();
    return true;
  }

  /// Corrige una compra registrada y ajusta el stock según los paquetes
  /// añadidos o quitados. Si es la compra más reciente, también corrige el
  /// costo actual del producto y opcionalmente su precio de venta.
  void editarCompra(
    String id, {
    required int paquetes,
    required double costoPaquete,
    required bool actualizarPrecio,
  }) {
    if (paquetes < 1 || !costoPaquete.isFinite || costoPaquete < 0) return;

    final indice = _compras.indexWhere((c) => c.id == id);
    if (indice == -1) return;

    final anterior = _compras[indice];
    if (anterior.tipo != TipoMovimientoCompra.compra) return;
    final esUltima = esUltimaCompra(anterior);
    final totalAnterior = anterior.total;
    final totalNuevo = paquetes * costoPaquete;
    final unidadesCambian =
        (paquetes - anterior.paquetes) * anterior.unidadesPorPaquete;
    final costoUnidad = anterior.unidadesPorPaquete > 0
        ? costoPaquete / anterior.unidadesPorPaquete
        : 0.0;
    final fecha = DateTime.now();

    _compras[indice] = anterior.conEdicion(
      paquetes: paquetes,
      costoPaquete: costoPaquete,
      edicion: EdicionCompra(
        fecha: fecha,
        totalAnterior: totalAnterior,
        totalNuevo: totalNuevo,
        cambio:
            'Costo del paquete: \$${anterior.costoPaquete.toStringAsFixed(2)} a \$${costoPaquete.toStringAsFixed(2)}; paquetes: ${anterior.paquetes} a $paquetes',
      ),
    );

    final indiceProducto = _productos.indexWhere(
      (p) => p.id == anterior.productoId,
    );
    if (indiceProducto != -1) {
      final producto = _productos[indiceProducto];
      final stockCalculado = producto.stock + unidadesCambian;
      final stockNuevo = stockCalculado < 0 ? 0 : stockCalculado;
      final precioNuevo = esUltima && actualizarPrecio && costoUnidad > 0
          ? precioDeVenta(costoUnidad)
          : null;

      _productos[indiceProducto] = producto.copyWith(
        stock: stockNuevo,
        stockMaximo: stockNuevo > producto.stockMaximo ? stockNuevo : null,
        precio: precioNuevo,
        costoPaquete: esUltima ? costoPaquete : null,
        unidadesPorPaquete: esUltima ? anterior.unidadesPorPaquete : null,
      );

      if (stockNuevo != producto.stock) {
        _movimientos.add(
          MovimientoInventario(
            productoId: producto.id,
            producto: producto.nombre,
            stockAnterior: producto.stock,
            stockNuevo: stockNuevo,
            motivo: 'Corrección de compra',
            nota:
                'Compra ${anterior.id}: ${unidadesCambian > 0 ? '+' : ''}$unidadesCambian unidades',
            fecha: fecha,
          ),
        );
      }
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
