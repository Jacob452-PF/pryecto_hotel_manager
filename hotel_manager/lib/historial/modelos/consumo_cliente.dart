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

  const ConsumoCliente({
    required this.cliente,
    required this.codigo,
    required this.lineas,
  });

  int get articulos => lineas.fold(0, (s, l) => s + l.cantidad);
  double get total => lineas.fold(0.0, (s, l) => s + l.importe);
}
