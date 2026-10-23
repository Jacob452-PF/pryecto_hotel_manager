import 'package:flutter/foundation.dart';

import '../../modelos/factura.dart';
import '../modelos/consumo_cliente.dart';
import '../modelos/turno_caja.dart';
import '../utilidades/sesion_actual.dart';

class _Cuenta {
  final String id;
  final String cliente;
  final String habitacion;
  final String registradoPor;
  Factura? factura;
  final List<LineaConsumo> iniciales = [];
  final List<LineaConsumo> anadidas = [];
  bool pagado = false;
  DateTime? pagadoEn;
  String metodoPago = '';

  _Cuenta(this.id, this.cliente, this.habitacion, this.registradoPor);
}

/// Libro de consumos del turno: guarda a cada cliente con todo lo que se le
/// ha cobrado desde el último cierre de caja, su factura completa, quién lo
/// registró y si ya pagó.
///
/// Lo llenan:
///  - "Nuevo huésped" (con `factura`): lo del registro (estadía y productos)
///  - "Tienda" (sin `factura`): lo que se añade después
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
        id: c.id,
        cliente: c.cliente,
        codigo: '#${c.habitacion}',
        lineas: List.unmodifiable(c.iniciales),
        lineasAnadidas: List.unmodifiable(c.anadidas),
        factura: c.factura,
        registradoPor: c.registradoPor,
        pagado: c.pagado,
        pagadoEn: c.pagadoEn,
        metodoPago: c.metodoPago,
      ),
  ];

  /// Suma [lineas] a la cuenta del cliente (la crea si es nuevo).
  /// Con [factura] son las líneas del registro; sin ella, lo añadido después.
  /// Si se añade algo a una cuenta ya pagada, vuelve a quedar pendiente.
  void registrar({
    required String cliente,
    required String habitacion,
    required List<LineaConsumo> lineas,
    Factura? factura,
  }) {
    if (lineas.isEmpty && factura == null) return;
    final id = '$habitacion|$cliente';
    final cuenta = _cuentas.putIfAbsent(
      id,
      () => _Cuenta(id, cliente, habitacion, nombreUsuarioActual()),
    );

    if (factura != null) {
      cuenta.factura = factura;
      for (final l in lineas) {
        _sumar(cuenta.iniciales, l);
      }
    } else {
      for (final l in lineas) {
        _sumar(cuenta.anadidas, l);
      }
      if (lineas.isNotEmpty) {
        cuenta.pagado = false;
        cuenta.pagadoEn = null;
      }
    }
    notifyListeners();
  }

  /// Marca la cuenta del cliente como pagada (o la vuelve a pendiente).
  void cambiarPago(String id, bool pagado) {
    final cuenta = _cuentas[id];
    if (cuenta == null) return;
    cuenta.pagado = pagado;
    cuenta.pagadoEn = pagado ? DateTime.now() : null;
    if (!pagado) cuenta.metodoPago = '';
    notifyListeners();
  }

  /// Registra el cobro de una estadía finalizada ("Finalizar estadía y cobrar").
  /// Si el cliente ya estaba en el turno, solo pasa a Pagado. Si no estaba
  /// (por ejemplo una habitación de ejemplo, o un huésped de otro turno), se
  /// agrega con lo que pagó. Siempre queda incluida la línea de la habitación.
  void registrarPago({
    required String habitacion,
    required String cliente,
    required String metodo,
    required double precioEstadia,
    required List<({String nombre, double precio, int cantidad})> cargos,
  }) {
    final id = '$habitacion|$cliente';
    final cuenta = _cuentas.putIfAbsent(id, () {
      final nueva = _Cuenta(id, cliente, habitacion, nombreUsuarioActual());
      for (final c in cargos) {
        _sumar(nueva.iniciales, LineaConsumo(c.nombre, c.precio, c.cantidad));
      }
      return nueva;
    });

    final tieneHabitacion = [
      ...cuenta.iniciales,
      ...cuenta.anadidas,
    ].any((l) => l.tipo == TipoVenta.habitaciones);
    if (!tieneHabitacion) {
      cuenta.iniciales.insert(
        0,
        LineaConsumo(
          'Habitación $habitacion',
          precioEstadia,
          1,
          TipoVenta.habitaciones,
        ),
      );
    }

    cuenta.pagado = true;
    cuenta.pagadoEn = DateTime.now();
    cuenta.metodoPago = metodo;
    notifyListeners();
  }

  /// Si el producto ya estaba en la lista, solo aumenta la cantidad.
  void _sumar(List<LineaConsumo> destino, LineaConsumo nueva) {
    final i = destino.indexWhere(
      (l) =>
          l.nombre == nueva.nombre &&
          l.precio == nueva.precio &&
          l.tipo == nueva.tipo,
    );
    if (i == -1) {
      destino.add(nueva);
    } else {
      final actual = destino[i];
      destino[i] = LineaConsumo(
        actual.nombre,
        actual.precio,
        actual.cantidad + nueva.cantidad,
        actual.tipo,
      );
    }
  }

  /// Se llama al cerrar el turno: la lista empieza de cero.
  void vaciar() {
    _cuentas.clear();
    notifyListeners();
  }
}
