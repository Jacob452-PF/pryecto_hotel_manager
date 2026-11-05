import 'dart:async';

import 'package:flutter/foundation.dart';

import '../tienda/modelos/articulo_tienda.dart';
import '../datos/tarifas_ejemplo.dart';
import '../modelos/habitacion.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import 'servicio_habitaciones.dart';
import 'servicio_storage.dart';
import 'servicio_reservas.dart';

class CargoEstadia {
  final String nombre;
  final double precio;
  final int cantidad;
  const CargoEstadia(this.nombre, this.precio, {this.cantidad = 1});
  double get importe => precio * cantidad;
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'precio': precio,
    'cantidad': cantidad,
  };
  factory CargoEstadia.fromJson(Map<String, dynamic> j) => CargoEstadia(
    j['nombre'] as String,
    (j['precio'] as num).toDouble(),
    cantidad: j['cantidad'] as int? ?? 1,
  );
}

class DatosEstadia {
  final DateTime entrada;
  final DateTime salida;
  final double precioEstadia;
  final String? huespedId;
  final String id;
  final DateTime createdAt;
  final List<CargoEstadia> cargosIniciales;
  final List<CargoEstadia> cargosTienda = [];
  DatosEstadia({
    required this.entrada,
    required this.salida,
    required this.precioEstadia,
    required this.cargosIniciales,
    this.huespedId,
    String? id,
    DateTime? createdAt,
  }) : id = id ?? 'est-${entrada.microsecondsSinceEpoch}',
       createdAt = createdAt ?? entrada;
  double get totalProductos =>
      [...cargosIniciales, ...cargosTienda].fold(0, (s, c) => s + c.importe);
  double get total => precioEstadia + totalProductos;
  Map<String, dynamic> toJson() => {
    'id': id,
    'huespedId': huespedId,
    'entrada': entrada.toIso8601String(),
    'salida': salida.toIso8601String(),
    'precioEstadia': precioEstadia,
    'createdAt': createdAt.toIso8601String(),
    'cargosIniciales': cargosIniciales.map((e) => e.toJson()).toList(),
    'cargosTienda': cargosTienda.map((e) => e.toJson()).toList(),
  };
  factory DatosEstadia.fromJson(Map<String, dynamic> j) {
    final d = DatosEstadia(
      id: j['id'] as String?,
      huespedId: j['huespedId'] as String?,
      entrada: DateTime.parse(j['entrada'] as String),
      salida: DateTime.parse(j['salida'] as String),
      precioEstadia: (j['precioEstadia'] as num).toDouble(),
      cargosIniciales: (j['cargosIniciales'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(CargoEstadia.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
    );
    d.cargosTienda.addAll(
      (j['cargosTienda'] as List? ?? []).cast<Map<String, dynamic>>().map(
        CargoEstadia.fromJson,
      ),
    );
    return d;
  }
}

/// Estado temporal de las estadías y cargos, compartido con la tienda.
class ServicioEstadias extends ChangeNotifier {
  ServicioEstadias._();
  static final instancia = ServicioEstadias._();
  final Map<String, DatosEstadia> _estadias = {};
  Map<String, DatosEstadia> get todas => Map.unmodifiable(_estadias);
  DatosEstadia? buscar(String habitacion) => _estadias[habitacion];

  Future<void> cargar() async {
    _estadias.clear();
    final filas = await ServicioStorage.instancia.leerLista('hotel.estadias');
    for (final fila in filas) {
      final habitacion = fila['habitacionId'] as String?;
      final data = fila['estadia'];
      if (habitacion != null && data is Map<String, dynamic>) {
        _estadias[habitacion] = DatosEstadia.fromJson(data);
      }
    }
    notifyListeners();
  }

  Future<void> _guardar() => ServicioStorage.instancia.guardarLista(
    'hotel.estadias',
    _estadias.entries
        .map((e) => {'habitacionId': e.key, 'estadia': e.value.toJson()})
        .toList(),
  );

  /// Las habitaciones ocupadas de demostración no tienen check-in en esta
  /// sesión. Al abrir su factura se les asigna una noche a la tarifa vigente.
  void asegurarEstadiaPredeterminada(String numeroHabitacion) {
    if (_estadias.containsKey(numeroHabitacion)) return;
    final habitacion = ServicioHabitaciones.instancia.buscar(numeroHabitacion);
    if (habitacion == null ||
        (habitacion.estado != EstadoHabitacion.ocupada &&
            habitacion.estado != EstadoHabitacion.ocupadaYLimpieza)) {
      return;
    }

    final camas = habitacion.tipoCuarto == TipoCuarto.familiar
        ? habitacion.camas
        : 1;
    final precio = tarifasEjemplo
        .firstWhere((tarifa) => tarifa.tipo == TipoTarifa.porNoche)
        .precioPara(camas);
    final entrada = DateTime.now();
    _estadias[numeroHabitacion] = DatosEstadia(
      entrada: entrada,
      salida: entrada.add(const Duration(days: 1)),
      precioEstadia: precio,
      cargosIniciales: const [],
    );
    unawaited(_guardar());
    notifyListeners();
  }

  void iniciar({
    required String habitacion,
    required DateTime entrada,
    required TipoTarifa tarifa,
    required int cantidad,
    required double precioUnitario,
    required List<CargoEstadia> productos,
    String? huespedId,
  }) {
    final duracion = tarifa == TipoTarifa.porHora
        ? Duration(hours: cantidad)
        : Duration(days: cantidad);
    final fin = entrada.add(duracion);
    if (!ServicioReservas.instancia.validarEstadiaContraReservas(
      habitacion: habitacion,
      inicio: entrada,
      fin: fin,
    )) {
      throw StateError(
        'La estadía se cruza con una reserva o no deja el margen de limpieza requerido.',
      );
    }
    _estadias[habitacion] = DatosEstadia(
      entrada: entrada,
      salida: fin,
      precioEstadia: precioUnitario * cantidad,
      cargosIniciales: List.unmodifiable(productos),
      huespedId: huespedId,
    );
    notifyListeners();
    unawaited(_guardar());
  }

  void agregarCargos(
    String habitacion,
    List<({ArticuloTienda articulo, int cantidad})> items,
  ) {
    final estadia = _estadias[habitacion];
    if (estadia == null) return;
    estadia.cargosTienda.addAll(
      items.map(
        (i) => CargoEstadia(
          i.articulo.nombre,
          i.articulo.precio,
          cantidad: i.cantidad,
        ),
      ),
    );
    notifyListeners();
    unawaited(_guardar());
  }

  void limpiar(String habitacion) {
    _estadias.remove(habitacion);
    unawaited(_guardar());
    notifyListeners();
  }
}
