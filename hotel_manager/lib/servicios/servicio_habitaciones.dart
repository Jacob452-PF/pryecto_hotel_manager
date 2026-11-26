import 'package:flutter/foundation.dart';

import '../modelos/habitacion.dart';
import '../modelos/usuario.dart';
import 'api_client.dart';
import 'servicio_sesion.dart';

/// Habitaciones cargadas desde la API. Los datos locales anteriores no se
/// borran, pero tampoco se muestran como si fueran datos del servidor.
class ServicioHabitaciones extends ChangeNotifier {
  ServicioHabitaciones._();

  static final instancia = ServicioHabitaciones._();

  final List<Habitacion> _habitaciones = [];
  List<Habitacion> get habitaciones => List.unmodifiable(_habitaciones);
  bool cargando = false;
  String? error;
  Map<String, dynamic> resumenApi = const {};
  bool _sincronizacionEnCurso = false;

  Future<void> cargar() => sincronizar();

  Future<void> sincronizar() async {
    if (_sincronizacionEnCurso) return;
    _sincronizacionEnCurso = true;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.rooms();
      final filas = ApiClient.instance.listFromResponse(
        response,
        collectionKey: 'rooms',
      );
      final habitaciones = filas
          .map(
            (fila) =>
                Habitacion.fromApiJson(Map<String, dynamic>.from(fila as Map)),
          )
          .toList();
      _habitaciones
        ..clear()
        ..addAll(habitaciones);
      resumenApi = response is Map && response['summary'] is Map
          ? Map<String, dynamic>.from(response['summary'] as Map)
          : const {};
    } on ApiException catch (e) {
      error = e.message;
    } on FormatException catch (e) {
      error =
          'La respuesta de habitaciones no tiene el formato esperado: ${e.message}';
    } catch (_) {
      error = 'No se pudieron cargar las habitaciones desde el servidor.';
    } finally {
      cargando = false;
      _sincronizacionEnCurso = false;
      notifyListeners();
    }
  }

  /// Estos cambios siguen siendo operaciones de interfaz transitorias hasta
  /// que reservas/estadías/tareas se ejecuten por sus endpoints propios.
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
      huespedDocumento: h.huespedDocumento,
      huespedTelefono: h.huespedTelefono,
      huespedIdApi: h.huespedIdApi,
      entradaEstadia: h.entradaEstadia,
      salidaEstadia: h.salidaEstadia,
      nombreTarifa: h.nombreTarifa,
      precioTarifa: h.precioTarifa,
      cantidadHuespedes: h.cantidadHuespedes,
      notasHabitacion: h.notasHabitacion,
      notasEstadia: h.notasEstadia,
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
    notifyListeners();
  }

  /// Un huésped entra a la habitación.
  void ocupar(String numero, String huesped) {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) return;
    _cambiarEstado(numero, EstadoHabitacion.ocupada, huesped: huesped);
  }

  bool reservar(String numero) {
    final h = buscar(numero);
    if (h == null || h.estado != EstadoHabitacion.disponible) return false;
    _cambiarEstado(numero, EstadoHabitacion.reservada);
    return true;
  }

  void liberarReserva(String numero) {
    if (buscar(numero)?.estado == EstadoHabitacion.reservada) {
      _cambiarEstado(numero, EstadoHabitacion.disponible);
    }
  }

  void terminarEstadia(String numero) {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) return;
    _cambiarEstado(numero, EstadoHabitacion.limpieza);
  }

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
        huespedDocumento: habitacion.huespedDocumento,
        huespedTelefono: habitacion.huespedTelefono,
        huespedIdApi: habitacion.huespedIdApi,
        entradaEstadia: habitacion.entradaEstadia,
        salidaEstadia: habitacion.salidaEstadia,
        nombreTarifa: habitacion.nombreTarifa,
        precioTarifa: habitacion.precioTarifa,
        cantidadHuespedes: habitacion.cantidadHuespedes,
        notasHabitacion: habitacion.notasHabitacion,
        notasEstadia: habitacion.notasEstadia,
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
      notifyListeners();
    } else if (habitacion.estado == EstadoHabitacion.disponible) {
      _cambiarEstado(numero, EstadoHabitacion.limpieza);
    }
  }

  void marcarLista(String numero) {
    final h = buscar(numero);
    final usuario = ServicioSesion.instancia.usuario;
    final autorizado =
        (h?.estado == EstadoHabitacion.limpieza &&
            usuario?.rol == RolUsuario.limpieza &&
            h?.asignadoLimpiezaId == usuario?.id) ||
        (h?.estado == EstadoHabitacion.mantenimiento &&
            usuario?.rol == RolUsuario.mantenimiento &&
            h?.asignadoMantenimientoId == usuario?.id);
    if (autorizado) _cambiarEstado(numero, EstadoHabitacion.disponible);
  }
}
