import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/notificacion_app.dart';
import '../modelos/reserva.dart';
import '../modelos/habitacion.dart';
import 'servicio_huespedes.dart';
import 'servicio_aviso_externo.dart';
import 'servicio_configuracion.dart';
import 'servicio_habitaciones.dart';
import '../modelos/usuario.dart';
import 'servicio_sesion.dart';
import 'servicio_notificaciones.dart';
import 'servicio_storage.dart';

class ServicioReservas extends ChangeNotifier {
  ServicioReservas._() {
    _reloj = Timer.periodic(
      const Duration(minutes: 1),
      (_) => procesarVencimientos(),
    );
  }
  static final instancia = ServicioReservas._();
  static const _clave = 'hotel.reservas';
  final List<Reserva> _reservas = [];
  Timer? _reloj;
  final AvisoExternoService _avisoExterno = const AvisoExternoService();
  List<Reserva> get reservas => List.unmodifiable(_reservas);

  Future<void> cargar() async {
    _reservas
      ..clear()
      ..addAll(
        (await ServicioStorage.instancia.leerLista(_clave))
            .map(Reserva.fromJson),
      );
    await procesarVencimientos();
    notifyListeners();
  }

  /// La estadía debe dejar el margen configurable antes del inicio reservado.
  bool validarChoque({
    required DateTime finEstadiaNueva,
    required DateTime inicioReserva,
  }) => !finEstadiaNueva
      .add(
        Duration(
          hours: ServicioConfiguracion
              .instancia
              .valor
              .margenDesocupacionLimpiezaHoras,
        ),
      )
      .isAfter(inicioReserva);

  bool validarEstadiaContraReservas({
    required String habitacion,
    required DateTime inicio,
    required DateTime fin,
  }) {
    final margen = Duration(
      hours:
          ServicioConfiguracion.instancia.valor.margenDesocupacionLimpiezaHoras,
    );
    final tolerancia = Duration(
      hours: ServicioConfiguracion
          .instancia
          .valor
          .toleranciaVencimientoReservaHoras,
    );
    for (final r in _reservas.where(
      (r) => r.habitacionId == habitacion && r.estado == EstadoReserva.activa,
    )) {
      final finReserva = r.fin.add(tolerancia);
      if (r.inicio.isBefore(fin) && inicio.isBefore(finReserva)) {
        return false;
      }
      if (!r.inicio.isBefore(inicio) && fin.add(margen).isAfter(r.inicio)) {
        return false;
      }
    }
    return true;
  }

  Future<Reserva> crear({
    required String huespedId,
    required String habitacionId,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin)
      throw StateError('Solo recepción o administración puede crear reservas.');
    if (!fin.isAfter(inicio)) {
      throw ArgumentError('La fecha final debe ser posterior a la inicial.');
    }
    final now = DateTime.now();
    if (inicio.isBefore(now)) {
      throw ArgumentError('La entrada de la reserva debe ser futura.');
    }
    final margen = Duration(
      hours:
          ServicioConfiguracion.instancia.valor.margenDesocupacionLimpiezaHoras,
    );
    final tolerancia = Duration(
      hours: ServicioConfiguracion
          .instancia
          .valor
          .toleranciaVencimientoReservaHoras,
    );
    if (_reservas.any(
      (r) =>
          r.habitacionId == habitacionId &&
          r.estado == EstadoReserva.activa &&
          ((inicio.isBefore(r.fin.add(tolerancia)) && r.inicio.isBefore(fin)) ||
              (!fin.isAfter(r.inicio) && fin.add(margen).isAfter(r.inicio)) ||
              (!inicio.isBefore(r.fin.add(tolerancia)) &&
                  r.fin.add(tolerancia + margen).isAfter(inicio))),
    )) {
      throw StateError(
        'La habitación ya tiene una reserva que se cruza con esas fechas.',
      );
    }
    final ocupada = ServicioHabitaciones.instancia.buscar(habitacionId);
    if (ocupada == null || ocupada.estado != EstadoHabitacion.disponible) {
      throw StateError('La habitación no está disponible para reservar.');
    }
    final reserva = Reserva(
      id: 'res-${now.microsecondsSinceEpoch}',
      huespedId: huespedId,
      habitacionId: habitacionId,
      inicio: inicio,
      fin: fin,
      createdAt: now,
    );
    _reservas.add(reserva);
    if (!inicio.isAfter(now)) {
      ServicioHabitaciones.instancia.reservar(habitacionId);
    }
    await _guardar();
    notifyListeners();
    return reserva;
  }

  Future<void> cancelar(String id) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin)
      throw StateError(
        'Solo recepción o administración puede cancelar reservas.',
      );
    final i = _reservas.indexWhere(
      (r) => r.id == id && r.estado == EstadoReserva.activa,
    );
    if (i < 0) return;
    final r = _reservas[i];
    _reservas[i] = r.copyWith(estado: EstadoReserva.cancelada);
    if (!_reservas.any(
      (x) =>
          x.id != id &&
          x.habitacionId == r.habitacionId &&
          x.estado == EstadoReserva.activa,
    )) {
      final otraActiva = _reservas.any(
        (x) =>
            x.id != r.id &&
            x.habitacionId == r.habitacionId &&
            x.estado == EstadoReserva.activa,
      );
      if (!otraActiva) {
        ServicioHabitaciones.instancia.liberarReserva(r.habitacionId);
      }
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> procesarVencimientos() async {
    final now = DateTime.now();
    var cambio = false;
    final tolerancia = Duration(
      hours: ServicioConfiguracion
          .instancia
          .valor
          .toleranciaVencimientoReservaHoras,
    );
    for (var i = 0; i < _reservas.length; i++) {
      final r = _reservas[i];
      if (r.estado != EstadoReserva.activa ||
          now.isBefore(r.fin.add(tolerancia))) {
        continue;
      }
      _reservas[i] = r.copyWith(
        estado: EstadoReserva.vencida,
        notificadaVencida: true,
      );
      ServicioHabitaciones.instancia.liberarReserva(r.habitacionId);
      ServicioNotificaciones.instancia.notificarEvento(
        id: 'reserva-vencida-${r.id}',
        titulo: 'Reserva vencida',
        mensaje: 'La reserva de la habitación ${r.habitacionId} venció.',
        severidad: SeveridadNotificacion.urgente,
      );
      // TODO(API): enviar notificación externa en el canal configurado.
      final coincidencias = ServicioHuespedes.instancia.huespedes.where(
        (h) => h.id == r.huespedId,
      );
      final huesped = coincidencias.isEmpty ? null : coincidencias.first;
      await _avisoExterno.enviar(
        destino: huesped?.telefono ?? r.huespedId,
        mensaje:
            ServicioConfiguracion.instancia.valor.plantillaMensajeVencimiento,
        canal: ServicioConfiguracion.instancia.valor.canalAvisoHuesped,
      );
      cambio = true;
    }
    _sincronizarEstados(now, tolerancia);
    if (cambio) {
      await _guardar();
      notifyListeners();
    }
  }

  void _sincronizarEstados(DateTime now, Duration tolerancia) {
    final vigentesAhora = _reservas
        .where(
          (r) =>
              r.estado == EstadoReserva.activa &&
              !now.isBefore(r.inicio) &&
              now.isBefore(r.fin.add(tolerancia)),
        )
        .map((r) => r.habitacionId)
        .toSet();
    final futuros = _reservas
        .where(
          (r) => r.estado == EstadoReserva.activa && now.isBefore(r.inicio),
        )
        .map((r) => r.habitacionId)
        .toSet();
    for (final numero in vigentesAhora) {
      ServicioHabitaciones.instancia.reservar(numero);
    }
    for (final numero in futuros) {
      if (!vigentesAhora.contains(numero)) {
        ServicioHabitaciones.instancia.liberarReserva(numero);
      }
    }
  }

  Future<void> _guardar() => ServicioStorage.instancia.guardarLista(
    _clave,
    _reservas.map((r) => r.toJson()).toList(),
  );
  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
