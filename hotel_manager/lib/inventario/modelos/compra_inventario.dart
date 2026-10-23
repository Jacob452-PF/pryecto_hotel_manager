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
  });

  /// Unidades que entraron al inventario.
  int get cantidad => paquetes * unidadesPorPaquete;

  /// Lo que costó cada unidad.
  double get costoUnitario =>
      unidadesPorPaquete > 0 ? costoPaquete / unidadesPorPaquete : 0;

  /// Lo que gastó el hotel en total: paquetes × costo del paquete.
  double get total => paquetes * costoPaquete;

  /// ¿Todavía no se ha cerrado en una caja?
  bool get enTurno => cajaNumero == null;

  CompraInventario cerrada(String numeroCaja) => CompraInventario(
    id: id,
    productoId: productoId,
    producto: producto,
    paquetes: paquetes,
    unidadesPorPaquete: unidadesPorPaquete,
    costoPaquete: costoPaquete,
    esNuevo: esNuevo,
    fecha: fecha,
    cajaNumero: numeroCaja,
  );
}
