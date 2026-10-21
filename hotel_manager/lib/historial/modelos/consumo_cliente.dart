import '../../modelos/factura.dart';
import 'turno_caja.dart';

/// Una línea de consumo (habitación, servicio o producto cobrado a un cliente).
class LineaConsumo {
  final String nombre;
  final double precio;
  final int cantidad;

  /// Sirve para armar "Detalle de ventas" en el cierre de caja.
  final TipoVenta tipo;

  const LineaConsumo(
    this.nombre,
    this.precio, [
    this.cantidad = 1,
    this.tipo = TipoVenta.productos,
  ]);

  double get importe => precio * cantidad;
}

/// Todo lo que consumió un cliente durante el turno.
class ConsumoCliente {
  final String cliente;

  /// Etiqueta que se muestra a la derecha, por ejemplo "#101".
  final String codigo;
  final List<LineaConsumo> lineas;

  /// Factura completa del registro del huésped: DUI, teléfono, habitación,
  /// tarifa, etc. Es null en los datos de ejemplo.
  final Factura? factura;

  /// Usuario que tenía la sesión abierta cuando se registró al cliente.
  final String registradoPor;

  const ConsumoCliente({
    required this.cliente,
    required this.codigo,
    required this.lineas,
    this.factura,
    this.registradoPor = '',
  });

  int get articulos => lineas.fold(0, (s, l) => s + l.cantidad);
  double get total => lineas.fold(0.0, (s, l) => s + l.importe);
}
