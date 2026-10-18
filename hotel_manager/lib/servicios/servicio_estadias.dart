import 'package:flutter/foundation.dart';

import '../tienda/modelos/articulo_tienda.dart';
import '../datos/tarifas_ejemplo.dart';
import '../modelos/habitacion.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import 'servicio_habitaciones.dart';

class CargoEstadia {
  final String nombre;
  final double precio;
  final int cantidad;
  const CargoEstadia(this.nombre, this.precio, {this.cantidad = 1});
  double get importe => precio * cantidad;
}

class DatosEstadia {
  final DateTime entrada;
  final DateTime salida;
  final double precioEstadia;
  final List<CargoEstadia> cargosIniciales;
  final List<CargoEstadia> cargosTienda = [];
  DatosEstadia({
    required this.entrada,
    required this.salida,
    required this.precioEstadia,
    required this.cargosIniciales,
  });
  double get totalProductos =>
      [...cargosIniciales, ...cargosTienda].fold(0, (s, c) => s + c.importe);
  double get total => precioEstadia + totalProductos;
}

/// Estado temporal de las estadías y cargos, compartido con la tienda.
class ServicioEstadias extends ChangeNotifier {
  ServicioEstadias._();
  static final instancia = ServicioEstadias._();
  final Map<String, DatosEstadia> _estadias = {};
  Map<String, DatosEstadia> get todas => Map.unmodifiable(_estadias);
  DatosEstadia? buscar(String habitacion) => _estadias[habitacion];

  /// Las habitaciones ocupadas de demostración no tienen check-in en esta
  /// sesión. Al abrir su factura se les asigna una noche a la tarifa vigente.
  void asegurarEstadiaPredeterminada(String numeroHabitacion) {
    if (_estadias.containsKey(numeroHabitacion)) return;
    final habitacion = ServicioHabitaciones.instancia.buscar(
      numeroHabitacion,
    );
    if (habitacion == null || habitacion.estado != EstadoHabitacion.ocupada) {
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
    notifyListeners();
  }

  void iniciar({
    required String habitacion,
    required DateTime entrada,
    required TipoTarifa tarifa,
    required int cantidad,
    required double precioUnitario,
    required List<CargoEstadia> productos,
  }) {
    final duracion = tarifa == TipoTarifa.porHora
        ? Duration(hours: cantidad)
        : Duration(days: cantidad);
    _estadias[habitacion] = DatosEstadia(
      entrada: entrada,
      salida: entrada.add(duracion),
      precioEstadia: precioUnitario * cantidad,
      cargosIniciales: List.unmodifiable(productos),
    );
    notifyListeners();
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
  }

  void limpiar(String habitacion) {
    _estadias.remove(habitacion);
    notifyListeners();
  }
}
