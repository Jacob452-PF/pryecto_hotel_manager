import 'habitacion.dart';
import 'producto.dart';
import 'tarifa.dart';

/// Factura inicial que se genera al registrar un huésped.
class Factura {
  final DateTime fecha;
  final String huesped;
  final String dui;
  final String telefono;
  final Habitacion habitacion;
  final TipoTarifa tarifa;
  final int cantidad; // horas o noches
  final double precioUnitario;
  final List<Producto> productos;

  const Factura({
    required this.fecha,
    required this.huesped,
    required this.dui,
    required this.telefono,
    required this.habitacion,
    required this.tarifa,
    required this.cantidad,
    required this.precioUnitario,
    required this.productos,
  });

  double get montoEstadia => precioUnitario * cantidad;

  double get montoProductos =>
      productos.fold(0.0, (suma, p) => suma + p.precio);

  double get total => montoEstadia + montoProductos;
}
