import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/notificacion_app.dart';
import '../modelos/reserva.dart';
import '../modelos/abono.dart';
import '../modelos/tipo_cuarto.dart';
import 'api_client.dart';
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
  String? error;

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

  Future<void> sincronizar() async {
    error = null;
    try {
      final recibidas = <Reserva>[];
      var page = 1;
      var lastPage = 1;
      do {
        final response = await ApiClient.instance.reservations(page: page);
        final rows = ApiClient.instance.listFromResponse(response);
        recibidas.addAll(
          rows.map(
            (row) => Reserva.fromApiJson(
              Map<String, dynamic>.from(row as Map),
            ),
          ),
        );
        if (response is Map) {
          lastPage = int.tryParse(response['last_page']?.toString() ?? '') ??
              page;
        }
        page++;
      } while (page <= lastPage);

      _reservas
        ..clear()
        ..addAll(recibidas);
    } on ApiException catch (e) {
      _reservas.clear();
      error = e.message;
    } on FormatException catch (e) {
      _reservas.clear();
      error = 'La respuesta de reservas no tiene el formato esperado: $e';
    } catch (_) {
      _reservas.clear();
      error = 'No se pudieron cargar las reservas desde el servidor.';
    } finally {
      notifyListeners();
    }
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
    required TipoCuarto tipoCuarto,
    required int camas,
    required int cantidad,
    required int tarifaId,
    required String tarifaNombre,
  }) async {
    final rol = ServicioSesion.instancia.usuario?.rol;
    if (rol != RolUsuario.recepcion && rol != RolUsuario.admin) {
      throw StateError('Solo recepción o administración puede crear reservas.');
    }
    if (!fin.isAfter(inicio)) {
      throw ArgumentError('La fecha final debe ser posterior a la inicial.');
    }
    final guestApiId = int.tryParse(huespedId);
    if (guestApiId == null) {
      throw StateError('El huésped no tiene un ID válido del servidor.');
    }
    final now = DateTime.now();
    if (inicio.isBefore(now)) {
      throw ArgumentError('La entrada de la reserva debe ser futura.');
    }
    final response = await ApiClient.instance.createReservation({
      'guest_id': guestApiId,
      'room_type': tipoCuarto.valorApi,
      'beds': camas,
      'rate_id': tarifaId,
      'rate_units': cantidad,
      'check_in_at': inicio.toIso8601String(),
      'expected_checkout_at': fin.toIso8601String(),
      'guests': 1,
    });
    final reserva = Reserva.fromApiJson(response);
    _reservas.removeWhere((r) => r.id == reserva.id);
    _reservas.add(reserva);
    final huesped = ServicioHuespedes.instancia.huespedes
        .where((h) => h.id == huespedId)
        .firstOrNull;
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'reserva-creada-${reserva.id}',
      titulo: 'Reserva creada',
      mensaje:
          '${huesped?.nombre ?? 'Huésped'} · ${tipoCuarto.etiqueta}, $camas ${camas == 1 ? 'cama' : 'camas'} · ${reserva.tarifaNombre ?? tarifaNombre} × $cantidad · ${_fechaHora(inicio)} a ${_fechaHora(fin)} · total ${reserva.total.toStringAsFixed(2)}.',
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
    await ApiClient.instance.cancelReservation(id);
    await sincronizar();
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

  Future<Map<String, dynamic>> registrarCheckIn(
    String id, {
    required String metodoPago,
  }) async {
    final response = await ApiClient.instance.checkInReservation(
      id,
      paymentMethod: metodoPago,
    );
    await sincronizar();
    return response;
  }

  Future<void> registrarAbono(
    String id, {
    required double monto,
    required MetodoAbono metodo,
  }) async {
    await ApiClient.instance.payReservation(
      id,
      amount: monto,
      paymentMethod: metodo.name,
    );
    await sincronizar();
  }
  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
