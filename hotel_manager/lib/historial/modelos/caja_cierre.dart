import 'consumo_cliente.dart';

/// Un cierre de caja guardado en el historial.
/// Cuando tengan base de datos, solo agreguen fromJson/toJson aquí.
class CajaCierre {
  /// Número con ceros, por ejemplo "001".
  final String numero;
  final DateTime fecha;
  final String cajero;

  /// Detalle por cliente (puede estar vacío si no se guardó el detalle).
  final List<ConsumoCliente> clientes;

  /// Total guardado al cerrar. Si es null, se suma el detalle de clientes.
  final double? totalRegistrado;

  const CajaCierre({
    required this.numero,
    required this.fecha,
    required this.cajero,
    this.clientes = const [],
    this.totalRegistrado,
  });

  double get total =>
      totalRegistrado ?? clientes.fold(0.0, (s, c) => s + c.total);
}
