import 'package:flutter/foundation.dart';

import '../../modelos/factura.dart';
import '../modelos/consumo_cliente.dart';
import '../utilidades/sesion_actual.dart';

class _Cuenta {
  final String cliente;
  final String habitacion;
  final String registradoPor;
  Factura? factura;
  final List<LineaConsumo> lineas = [];

  _Cuenta(this.cliente, this.habitacion, this.registradoPor);
}

/// Libro de consumos del turno: guarda a cada cliente con todo lo que se le
/// ha cobrado desde el último cierre de caja, su factura completa y el
/// usuario que lo registró.
///
/// Lo llenan:
///  - "Nuevo huésped" (la factura, la estadía y los productos del catálogo)
///  - "Tienda" (cuando se carga una compra a una habitación)
/// Y lo lee "Cierre de caja". Vive en memoria; con base de datos solo se
/// cambia este archivo.
class ServicioConsumos extends ChangeNotifier {
  ServicioConsumos._();

  static final ServicioConsumos instancia = ServicioConsumos._();

  final Map<String, _Cuenta> _cuentas = {};

  /// Clientes del turno, en el orden en que se registraron.
  List<ConsumoCliente> get clientes => [
    for (final c in _cuentas.values)
      ConsumoCliente(
        cliente: c.cliente,
        codigo: '#${c.habitacion}',
        lineas: List.unmodifiable(c.lineas),
        factura: c.factura,
        registradoPor: c.registradoPor,
      ),
  ];

  /// Suma [lineas] a la cuenta del cliente (la crea si es nuevo).
  /// Si el cliente ya tenía ese mismo producto, solo aumenta la cantidad.
  /// Al registrar un huésped nuevo se pasa también su [factura] completa.
  void registrar({
    required String cliente,
    required String habitacion,
    required List<LineaConsumo> lineas,
    Factura? factura,
  }) {
    if (lineas.isEmpty && factura == null) return;
    final cuenta = _cuentas.putIfAbsent(
      '$habitacion|$cliente',
      () => _Cuenta(cliente, habitacion, nombreUsuarioActual()),
    );
    if (factura != null) cuenta.factura = factura;

    for (final nueva in lineas) {
      final i = cuenta.lineas.indexWhere(
        (l) =>
            l.nombre == nueva.nombre &&
            l.precio == nueva.precio &&
            l.tipo == nueva.tipo,
      );
      if (i == -1) {
        cuenta.lineas.add(nueva);
      } else {
        final actual = cuenta.lineas[i];
        cuenta.lineas[i] = LineaConsumo(
          actual.nombre,
          actual.precio,
          actual.cantidad + nueva.cantidad,
          actual.tipo,
        );
      }
    }
    notifyListeners();
  }

  /// Se llama al cerrar el turno: la lista empieza de cero.
  void vaciar() {
    _cuentas.clear();
    notifyListeners();
  }
}
