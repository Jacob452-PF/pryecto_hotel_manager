import 'package:flutter/foundation.dart';

import '../datos/habitaciones_ejemplo.dart';
import '../modelos/habitacion.dart';

/// Guarda el estado actual de las habitaciones y avisa a las pantallas cuando
/// cambia. Por ahora vive en memoria: al cerrar la app se vuelve a los datos de
/// ejemplo. Cuando haya base de datos, solo se cambia este archivo.
class ServicioHabitaciones extends ChangeNotifier {
  ServicioHabitaciones._();

  static final ServicioHabitaciones instancia = ServicioHabitaciones._();

  final List<Habitacion> _habitaciones = List.of(habitacionesEjemplo);

  List<Habitacion> get habitaciones => List.unmodifiable(_habitaciones);

  Habitacion? buscar(String numero) {
    for (final habitacion in _habitaciones) {
      if (habitacion.numero == numero) return habitacion;
    }
    return null;
  }

  void _cambiarEstado(
    String numero,
    EstadoHabitacion estado, {
    String? huesped,
  }) {
    final indice = _habitaciones.indexWhere((h) => h.numero == numero);
    if (indice == -1) return;
    _habitaciones[indice] = _habitaciones[indice].conEstado(
      estado,
      huesped: huesped,
    );
    notifyListeners();
  }

  /// Un huésped entra a la habitación.
  void ocupar(String numero, String huesped) =>
      _cambiarEstado(numero, EstadoHabitacion.ocupada, huesped: huesped);

  /// El huésped se va: la habitación pasa a limpieza.
  void terminarEstadia(String numero) =>
      _cambiarEstado(numero, EstadoHabitacion.limpieza);

  /// Limpieza o reparación terminada: vuelve a estar disponible.
  void marcarLista(String numero) =>
      _cambiarEstado(numero, EstadoHabitacion.disponible);

  void enviarAMantenimiento(String numero) =>
      _cambiarEstado(numero, EstadoHabitacion.mantenimiento);
}
