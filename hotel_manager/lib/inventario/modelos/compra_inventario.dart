/// Una corrección hecha a una compra (por ejemplo, el costo estaba mal escrito).
/// Se guarda para que en Cierre de caja se vea cuánto se gastó antes y después.
class EdicionCompra {
  final DateTime fecha;
  final double totalAnterior;
  final double totalNuevo;

  /// Qué cambió, por ejemplo "Costo del paquete $13.80 → $8.28".
  final String cambio;

  const EdicionCompra({
    required this.fecha,
    required this.totalAnterior,
    required this.totalNuevo,
    required this.cambio,
  });
}

/// Una compra de mercadería: lo que el hotel gastó al agregar un producto
/// nuevo o al reponer su stock. Se compra por PAQUETES.
/// Cuando tengan base de datos, se guarda cada compra en una tabla.
class CompraInventario {
  final String id;
  final String productoId;
  final String producto;

  /// Cuántos paquetes se compraron.
  final int paquetes;

  /// Unidades que trae cada paquete.
  final int unidadesPorPaquete;

  /// Lo que costó cada paquete.
  final double costoPaquete;

  /// true: producto nuevo; false: reposición de stock.
  final bool esNuevo;
  final DateTime fecha;

  /// Número de la caja en que se cerró este gasto (null = todavía del turno actual).
  final String? cajaNumero;

  /// Correcciones que se le han hecho, de la más antigua a la más reciente.
  final List<EdicionCompra> ediciones;

  const CompraInventario({
    required this.id,
    required this.productoId,
    required this.producto,
    required this.paquetes,
    required this.unidadesPorPaquete,
    required this.costoPaquete,
    required this.esNuevo,
    required this.fecha,
    this.cajaNumero,
    this.ediciones = const [],
  });

  /// Unidades que entraron al inventario.
  int get cantidad => paquetes * unidadesPorPaquete;

  /// Lo que costó cada unidad.
  double get costoUnitario =>
      unidadesPorPaquete > 0 ? costoPaquete / unidadesPorPaquete : 0;

  /// Lo que gastó el hotel en total (ya con las correcciones).
  double get total => paquetes * costoPaquete;

  /// ¿Se corrigió alguna vez?
  bool get editada => ediciones.isNotEmpty;

  /// Lo que se había anotado antes de la primera corrección.
  double get totalOriginal => editada ? ediciones.first.totalAnterior : total;

  /// ¿Todavía no se ha cerrado en una caja?
  bool get enTurno => cajaNumero == null;

  CompraInventario _copia({
    int? paquetes,
    double? costoPaquete,
    String? cajaNumero,
    List<EdicionCompra>? ediciones,
  }) => CompraInventario(
    id: id,
    productoId: productoId,
    producto: producto,
    paquetes: paquetes ?? this.paquetes,
    unidadesPorPaquete: unidadesPorPaquete,
    costoPaquete: costoPaquete ?? this.costoPaquete,
    esNuevo: esNuevo,
    fecha: fecha,
    cajaNumero: cajaNumero ?? this.cajaNumero,
    ediciones: ediciones ?? this.ediciones,
  );

  CompraInventario cerrada(String numeroCaja) => _copia(cajaNumero: numeroCaja);

  CompraInventario conEdicion({
    required int paquetes,
    required double costoPaquete,
    required EdicionCompra edicion,
  }) => _copia(
    paquetes: paquetes,
    costoPaquete: costoPaquete,
    ediciones: [...ediciones, edicion],
  );
}
