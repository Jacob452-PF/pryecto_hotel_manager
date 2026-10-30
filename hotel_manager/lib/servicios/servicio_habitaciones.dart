import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/habitaciones_ejemplo.dart';
import '../modelos/habitacion.dart';
import '../modelos/usuario.dart';
import 'servicio_storage.dart';
import 'servicio_sesion.dart';

/// Guarda el estado actual de las habitaciones y avisa a las pantallas cuando
/// cambia. Por ahora vive en memoria: al cerrar la app se vuelve a los datos de
/// ejemplo. Cuando haya base de datos, solo se cambia este archivo.
class ServicioHabitaciones extends ChangeNotifier {
  ServicioHabitaciones._();

  static final ServicioHabitaciones instancia = ServicioHabitaciones._();

  final List<Habitacion> _habitaciones = List.of(habitacionesEjemplo);

  List<Habitacion> get habitaciones => List.unmodifiable(_habitaciones);

  Future<void> cargar() async {
    final filas = await ServicioStorage.instancia.leerLista(
      'hotel.habitaciones',
    );
    if (filas.isEmpty) return;
    _habitaciones
      ..clear()
      ..addAll(filas.map(Habitacion.fromJson));
    notifyListeners();
  }

  Future<void> _guardar() => ServicioStorage.instancia.guardarLista(
    'hotel.habitaciones',
    _habitaciones.map((h) => h.toJson()).toList(),
  );

  void actualizarPorTarea(
    String numero, {
    EstadoHabitacion? estado,
    String? asignadoLimpiezaId,
    String? asignadoMantenimientoId,
    bool limpiarAsignacionLimpieza = false,
    bool limpiarAsignacionMantenimiento = false,
    bool? limpiezaSolicitada,
    String? descripcionLimpieza,
    bool limpiarDescripcion = false,
  }) {
    final i = _habitaciones.indexWhere((h) => h.numero == numero);
    if (i < 0) return;
    final h = _habitaciones[i];
    _habitaciones[i] = Habitacion(
      h.numero,
      h.piso,
      h.tipoCuarto,
      estado ?? h.estado,
      camas: h.camas,
      huesped: h.huesped,
      limpiezaSolicitada: limpiezaSolicitada ?? h.limpiezaSolicitada,
      rutaFoto: h.rutaFoto,
      id: h.id,
      descripcionLimpieza: limpiarDescripcion
          ? null
          : (descripcionLimpieza ?? h.descripcionLimpieza),
      asignadoLimpiezaId: limpiarAsignacionLimpieza
          ? null
          : (asignadoLimpiezaId ?? h.asignadoLimpiezaId),
      asignadoMantenimientoId: limpiarAsignacionMantenimiento
          ? null
          : (asignadoMantenimientoId ?? h.asignadoMantenimientoId),
      reservaActivaId: h.reservaActivaId,
      estadiaActivaId: h.estadiaActivaId,
      updatedAt: DateTime.now(),
    );
    unawaited(_guardar());
    notifyListeners();
  }

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
    unawaited(_guardar());
    notifyListeners();
  }

  /// Un huésped entra a la habitación.
  void ocupar(String numero, String huesped) {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) return;
    _cambiarEstado(numero, EstadoHabitacion.ocupada, huesped: huesped);
  }

  /// Una reserva ocupa el estado de la habitación al llegar su hora de entrada.
  bool reservar(String numero) {
    final h = buscar(numero);
    if (h == null || h.estado != EstadoHabitacion.disponible) return false;
    _cambiarEstado(numero, EstadoHabitacion.reservada);
    return true;
  }

  /// Libera únicamente habitaciones que siguen reservadas.
  void liberarReserva(String numero) {
    if (buscar(numero)?.estado == EstadoHabitacion.reservada) {
      _cambiarEstado(numero, EstadoHabitacion.disponible);
    }
  }

  /// El huésped se va: la habitación pasa a limpieza.
  void terminarEstadia(String numero) {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) return;
    _cambiarEstado(numero, EstadoHabitacion.limpieza);
  }

  /// Solicita limpieza y mantiene el indicador de que la habitación sigue ocupada.
  void solicitarLimpieza(String numero) {
    final indice = _habitaciones.indexWhere((h) => h.numero == numero);
    if (indice == -1) return;
    final habitacion = _habitaciones[indice];
    if (habitacion.estado == EstadoHabitacion.ocupada ||
        habitacion.estado == EstadoHabitacion.ocupadaYLimpieza) {
      if (habitacion.limpiezaSolicitada) return;
      _habitaciones[indice] = Habitacion(
        habitacion.numero,
        habitacion.piso,
        habitacion.tipoCuarto,
        EstadoHabitacion.ocupadaYLimpieza,
        camas: habitacion.camas,
        huesped: habitacion.huesped,
        limpiezaSolicitada: true,
        rutaFoto: habitacion.rutaFoto,
        id: habitacion.id,
        descripcionLimpieza: habitacion.descripcionLimpieza,
        asignadoLimpiezaId: habitacion.asignadoLimpiezaId,
        asignadoMantenimientoId: habitacion.asignadoMantenimientoId,
        reservaActivaId: habitacion.reservaActivaId,
        estadiaActivaId: habitacion.estadiaActivaId,
        updatedAt: DateTime.now(),
      );
      unawaited(_guardar());
      notifyListeners();
    } else if (habitacion.estado == EstadoHabitacion.disponible) {
      _cambiarEstado(numero, EstadoHabitacion.limpieza);
    }
  }

  /// Solo el empleado asignado puede cerrar la tarea correspondiente.
  void marcarLista(String numero) {
    final h = buscar(numero);
    final u = ServicioSesion.instancia.usuario;
    final autorizado =
        (h?.estado == EstadoHabitacion.limpieza &&
            u?.rol == RolUsuario.limpieza &&
            h?.asignadoLimpiezaId == u?.id) ||
        (h?.estado == EstadoHabitacion.mantenimiento &&
            u?.rol == RolUsuario.mantenimiento &&
            h?.asignadoMantenimientoId == u?.id);
    if (autorizado) _cambiarEstado(numero, EstadoHabitacion.disponible);
  }
}
