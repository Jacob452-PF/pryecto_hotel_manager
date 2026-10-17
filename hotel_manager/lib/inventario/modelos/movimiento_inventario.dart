/// Registro de un ajuste de stock (quién cambió qué, cuándo y por qué).
/// Cuando tengan base de datos, se guarda cada movimiento en una tabla.
class MovimientoInventario {
  final String productoId;
  final String producto;
  final int stockAnterior;
  final int stockNuevo;
  final String motivo;
  final String nota;
  final DateTime fecha;

  const MovimientoInventario({
    required this.productoId,
    required this.producto,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.motivo,
    required this.nota,
    required this.fecha,
  });
}
