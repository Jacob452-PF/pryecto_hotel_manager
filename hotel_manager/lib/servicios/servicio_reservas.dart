import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/notificacion_app.dart';
import '../modelos/reserva.dart';
import '../modelos/tipo_cuarto.dart';
import '../modelos/tarifa.dart';
import 'servicio_huespedes.dart';
import 'servicio_aviso_externo.dart';
import 'servicio_configuracion.dart';
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

  /// Una solicitud todavía no asigna una habitación concreta.
  bool validarEstadiaContraReservas({
    required String habitacion,
    required DateTime inicio,
    required DateTime fin,
  }) => fin.isAfter(inicio);

  Future<Reserva> crear({
    required String huespedId,
    required DateTime inicio,
    required DateTime fin,
    required double total,
    required TipoCuarto tipoCuarto,
    required int camas,
    required TipoTarifa tarifa,
    required int cantidad,
  }) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) {
      throw StateError('Solo recepción o administración puede crear reservas.');
    }
    if (!fin.isAfter(inicio)) {
      throw ArgumentError('La fecha final debe ser posterior a la inicial.');
    }
    final now = DateTime.now();
    if (inicio.isBefore(now)) {
      throw ArgumentError('La entrada de la reserva debe ser futura.');
    }
    final reserva = Reserva(
      id: 'res-${now.microsecondsSinceEpoch}',
      huespedId: huespedId,
      inicio: inicio,
      fin: fin,
      total: total,
      tipoCuarto: tipoCuarto,
      camas: camas,
      tarifa: tarifa,
      cantidad: cantidad,
      createdAt: now,
    );
    // Persist before publishing the reservation to listeners. If the platform
    // storage channel stalls or fails, the UI can report the error instead of
    // leaving a half-created reservation in memory.
    final reservasAnteriores = List<Reserva>.of(_reservas);
    _reservas.add(reserva);
    try {
      await _guardar().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw StateError(
          'El almacenamiento tardó demasiado. Intenta guardar la reserva otra vez.',
        ),
      );
    } on Object {
      _reservas
        ..clear()
        ..addAll(reservasAnteriores);
      rethrow;
    }
    final huesped = ServicioHuespedes.instancia.huespedes
        .where((h) => h.id == huespedId)
        .firstOrNull;
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'reserva-creada-${reserva.id}',
      titulo: 'Reserva creada',
      mensaje:
          '${huesped?.nombre ?? 'Huésped'} · ${tipoCuarto.etiqueta}, $camas ${camas == 1 ? 'cama' : 'camas'} · ${tarifa.etiqueta} × $cantidad · ${_fechaHora(inicio)} a ${_fechaHora(fin)} · total ${total.toStringAsFixed(2)}.',
      severidad: SeveridadNotificacion.leve,
    );
    notifyListeners();
    return reserva;
  }

  String _fechaHora(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  Future<void> cancelar(String id) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) {
      throw StateError(
        'Solo recepción o administración puede cancelar reservas.',
      );
    }
    final i = _reservas.indexWhere(
      (r) => r.id == id && r.estado == EstadoReserva.activa,
    );
    if (i < 0) return;
    final r = _reservas[i];
    _reservas[i] = r.copyWith(estado: EstadoReserva.cancelada);
    await _guardar();
    notifyListeners();
  }

  Future<void> marcarConvertida(String id) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) {
      throw StateError(
        'Solo recepción o administración puede convertir reservas.',
      );
    }
    final i = _reservas.indexWhere(
      (r) => r.id == id && r.estado == EstadoReserva.activa,
    );
    if (i < 0) throw StateError('La reserva ya no está activa.');
    _reservas[i] = _reservas[i].copyWith(estado: EstadoReserva.convertida);
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
      ServicioNotificaciones.instancia.notificarEvento(
        id: 'reserva-vencida-${r.id}',
        titulo: 'Reserva vencida',
        mensaje: 'La solicitud de ${_nombreHuesped(r.huespedId)} venció.',
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
    if (cambio) {
      await _guardar();
      notifyListeners();
    }
  }

  String _nombreHuesped(String id) => ServicioHuespedes.instancia.huespedes
      .where((h) => h.id == id)
      .map((h) => h.nombre)
      .firstOrNull ?? 'Huésped';

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
