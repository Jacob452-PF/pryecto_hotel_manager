import 'package:flutter/foundation.dart';

import '../utilidades/tiempo_hotel.dart';
import 'api_client.dart';

class CargoEstadia {
  final String nombre;
  final double precio;
  final int cantidad;
  final bool pagado;

  const CargoEstadia(
    this.nombre,
    this.precio, {
    this.cantidad = 1,
    this.pagado = false,
  });
  double get importe => precio * cantidad;

  factory CargoEstadia.fromApi(Map<String, dynamic> json) => CargoEstadia(
    json['description']?.toString() ?? 'Consumo adicional',
    double.tryParse(json['amount']?.toString() ?? '') ?? 0,
    pagado: json['paid_at'] != null,
  );
}

class DatosEstadia {
  final DateTime entrada;
  final DateTime salida;
  final double precioEstadia;
  final String? huespedId;
  final String id;
  final List<CargoEstadia> cargosIniciales;
  final List<CargoEstadia> cargosTienda;

  const DatosEstadia({
    required this.id,
    required this.entrada,
    required this.salida,
    required this.precioEstadia,
    required this.cargosIniciales,
    required this.cargosTienda,
    this.huespedId,
  });

  double get totalProductos =>
      [...cargosIniciales, ...cargosTienda].fold(0, (s, c) => s + c.importe);
  double get total => precioEstadia + totalProductos;
  double get saldoCargos => [...cargosIniciales, ...cargosTienda]
      .where((charge) => !charge.pagado)
      .fold(0, (sum, charge) => sum + charge.importe);

  factory DatosEstadia.fromApi(Map<String, dynamic> json) {
    final rate = json['rate'] is Map
        ? Map<String, dynamic>.from(json['rate'] as Map)
        : const <String, dynamic>{};
    final guest = json['guest'] is Map
        ? Map<String, dynamic>.from(json['guest'] as Map)
        : const <String, dynamic>{};
    final charges = json['charges'] is List
        ? (json['charges'] as List)
              .whereType<Map>()
              .map(
                (row) => CargoEstadia.fromApi(Map<String, dynamic>.from(row)),
              )
              .toList()
        : <CargoEstadia>[];
    final units = int.tryParse(json['rate_units']?.toString() ?? '') ?? 1;
    return DatosEstadia(
      id: json['id'].toString(),
<<<<<<< Updated upstream
      entrada: TiempoHotel.desdeApi(json['check_in_at'].toString()),
      salida: TiempoHotel.desdeApi(json['expected_checkout_at'].toString()),
=======
      entrada: DateTime.parse(json['check_in_at'].toString()),
      salida: DateTime.parse(json['expected_checkout_at'].toString()),
>>>>>>> Stashed changes
      precioEstadia:
          (double.tryParse(rate['price']?.toString() ?? '') ?? 0) * units,
      cargosIniciales: const [],
      cargosTienda: charges,
      huespedId: (json['guest_id'] ?? guest['id'])?.toString(),
    );
  }
}

/// Instantánea en memoria de estadías leídas del backend. El servidor sigue
/// siendo la fuente de verdad; no se cargan estadías guardadas en el teléfono.
class ServicioEstadias extends ChangeNotifier {
  ServicioEstadias._();
  static final instancia = ServicioEstadias._();

  final Map<String, DatosEstadia> _estadias = {};
  Map<String, DatosEstadia> get todas => Map.unmodifiable(_estadias);
  DatosEstadia? buscar(String habitacion) => _estadias[habitacion];
  bool cargando = false;
  String? error;
  bool _sincronizacionEnCurso = false;

  Future<void> cargar() => sincronizar();

  Future<void> sincronizar() async {
    if (_sincronizacionEnCurso) return;
    _sincronizacionEnCurso = true;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final rooms = <String, DatosEstadia>{};
      var page = 1;
      var lastPage = 1;
      do {
        final response = await ApiClient.instance.stays(page: page);
        final rows = ApiClient.instance.listFromResponse(response);
        for (final row in rows) {
          final json = Map<String, dynamic>.from(row as Map);
          if (json['status'] != 'activa') continue;
          final room = json['room'] is Map
              ? Map<String, dynamic>.from(json['room'] as Map)
              : const <String, dynamic>{};
          final number = (room['number'] ?? '').toString();
          if (number.isNotEmpty) rooms[number] = DatosEstadia.fromApi(json);
        }
        if (response is Map) {
          final meta = response['meta'];
          lastPage =
              int.tryParse(
                (response['last_page'] ??
                            (meta is Map ? meta['last_page'] : null))
                        ?.toString() ??
                    '',
              ) ??
              page;
        }
        page++;
      } while (page <= lastPage);
      _estadias
        ..clear()
        ..addAll(rooms);
    } on Object catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      _sincronizacionEnCurso = false;
      notifyListeners();
    }
  }

  /// No inventa una estadía para habitaciones que no tengan check-in remoto.
  void asegurarEstadiaPredeterminada(String numeroHabitacion) {}

  void limpiar(String habitacion) {
    _estadias.remove(habitacion);
    notifyListeners();
  }
}
