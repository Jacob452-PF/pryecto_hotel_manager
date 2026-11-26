import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../utilidades/tiempo_hotel.dart';
import 'tipo_cuarto.dart';

enum EstadoHabitacion {
  disponible('Disponible', ColoresApp.disponible, Icons.check_circle),
  ocupada('Ocupada', ColoresApp.ocupada, Icons.bed),
  ocupadaYLimpieza(
    'Ocupada y limpieza',
    ColoresApp.ocupada,
    Icons.cleaning_services,
  ),
  limpieza('En limpieza', ColoresApp.limpieza, Icons.cleaning_services),
  reservada('Reservada', ColoresApp.reservada, Icons.event),
  mantenimiento('Mantenimiento', ColoresApp.mantenimiento, Icons.build);

  String get valor => switch (this) {
    EstadoHabitacion.disponible => 'disponible',
    EstadoHabitacion.ocupada => 'ocupada',
    EstadoHabitacion.ocupadaYLimpieza => 'ocupada_y_limpieza',
    EstadoHabitacion.limpieza => 'limpieza',
    EstadoHabitacion.reservada => 'reservada',
    EstadoHabitacion.mantenimiento => 'mantenimiento',
  };

  static EstadoHabitacion desdeJson(String value) => EstadoHabitacion.values
      .firstWhere((e) => e.valor == value, orElse: () => disponible);

  const EstadoHabitacion(this.etiqueta, this.color, this.icono);
  final String etiqueta;
  final Color color;
  final IconData icono;
}

class Habitacion {
  final String id;
  final String numero;
  final int piso;

  /// Común (una cama) o especial (matrimonial o familiar).
  final TipoCuarto tipoCuarto;
  final EstadoHabitacion estado;

  /// Cantidad de camas. Las comunes tienen una; las especiales pueden tener
  /// una (matrimonial) o más (familiar).
  final int camas;

  /// Nombre del huésped que la ocupa (solo si el estado es ocupada).
  final String? huesped;
<<<<<<< Updated upstream
  final String? huespedDocumento;
  final String? huespedTelefono;
  final String? huespedIdApi;
=======
  final String? huespedId;
  final String? huespedDocumento;
  final String? huespedTelefono;
  final String? huespedCorreo;
>>>>>>> Stashed changes
  final DateTime? entradaEstadia;
  final DateTime? salidaEstadia;
  final String? nombreTarifa;
  final double? precioTarifa;
  final int? cantidadHuespedes;
  final String? notasHabitacion;
  final String? notasEstadia;

  /// Servicio de limpieza solicitado durante una estadía activa.
  final bool limpiezaSolicitada;

  /// Ruta de la foto de la habitación. Es null hasta que se tome la foto
  /// al agregar la habitación al catálogo.
  final String? rutaFoto;
  final String? descripcionLimpieza;
  final String? asignadoLimpiezaId;
  final String? asignadoMantenimientoId;
  final String? reservaActivaId;
  final String? estadiaActivaId;
  final DateTime? _updatedAt;
  DateTime get updatedAt =>
      _updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  const Habitacion(
    this.numero,
    this.piso,
    this.tipoCuarto,
    this.estado, {
    this.camas = 1,
    this.huesped,
<<<<<<< Updated upstream
    this.huespedDocumento,
    this.huespedTelefono,
    this.huespedIdApi,
=======
    this.huespedId,
    this.huespedDocumento,
    this.huespedTelefono,
    this.huespedCorreo,
>>>>>>> Stashed changes
    this.entradaEstadia,
    this.salidaEstadia,
    this.nombreTarifa,
    this.precioTarifa,
    this.cantidadHuespedes,
    this.notasHabitacion,
    this.notasEstadia,
    this.limpiezaSolicitada = false,
    this.rutaFoto,
    String? id,
    this.descripcionLimpieza,
    this.asignadoLimpiezaId,
    this.asignadoMantenimientoId,
    this.reservaActivaId,
    this.estadiaActivaId,
    DateTime? updatedAt,
  }) : id = id ?? numero,
       _updatedAt = updatedAt;

  /// Copia de la habitación con otro estado. El huésped se reemplaza por el
  /// que se indique; si no se indica ninguno, queda sin huésped.
  Habitacion conEstado(EstadoHabitacion nuevoEstado, {String? huesped}) {
    return Habitacion(
      numero,
      piso,
      tipoCuarto,
      nuevoEstado,
      camas: camas,
      huesped: huesped,
<<<<<<< Updated upstream
      huespedDocumento: huespedDocumento,
      huespedTelefono: huespedTelefono,
      huespedIdApi: huespedIdApi,
=======
      huespedId: huespedId,
      huespedDocumento: huespedDocumento,
      huespedTelefono: huespedTelefono,
      huespedCorreo: huespedCorreo,
>>>>>>> Stashed changes
      entradaEstadia: entradaEstadia,
      salidaEstadia: salidaEstadia,
      nombreTarifa: nombreTarifa,
      precioTarifa: precioTarifa,
      cantidadHuespedes: cantidadHuespedes,
      notasHabitacion: notasHabitacion,
      notasEstadia: notasEstadia,
      limpiezaSolicitada:
          nuevoEstado == EstadoHabitacion.ocupadaYLimpieza ||
          (nuevoEstado == EstadoHabitacion.limpieza && limpiezaSolicitada),
      rutaFoto: rutaFoto,
      id: id,
      descripcionLimpieza: descripcionLimpieza,
      asignadoLimpiezaId: asignadoLimpiezaId,
      asignadoMantenimientoId: asignadoMantenimientoId,
      reservaActivaId: reservaActivaId,
      estadiaActivaId: estadiaActivaId,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'piso': piso,
    'tipoCuarto': tipoCuarto.name,
    'estado': estado.valor,
    'camas': camas,
    'huesped': huesped,
<<<<<<< Updated upstream
    'huespedDocumento': huespedDocumento,
    'huespedTelefono': huespedTelefono,
    'huespedIdApi': huespedIdApi,
=======
    'huespedId': huespedId,
    'huespedDocumento': huespedDocumento,
    'huespedTelefono': huespedTelefono,
    'huespedCorreo': huespedCorreo,
>>>>>>> Stashed changes
    'entradaEstadia': entradaEstadia?.toIso8601String(),
    'salidaEstadia': salidaEstadia?.toIso8601String(),
    'nombreTarifa': nombreTarifa,
    'precioTarifa': precioTarifa,
    'cantidadHuespedes': cantidadHuespedes,
    'notasHabitacion': notasHabitacion,
    'notasEstadia': notasEstadia,
    'limpiezaSolicitada': limpiezaSolicitada,
    'rutaFoto': rutaFoto,
    'descripcionLimpieza': descripcionLimpieza,
    'asignadoLimpiezaId': asignadoLimpiezaId,
    'asignadoMantenimientoId': asignadoMantenimientoId,
    'reservaActivaId': reservaActivaId,
    'estadiaActivaId': estadiaActivaId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Mapea una habitación del API sin convertir errores de esquema en datos
  /// de ejemplo. Se aceptan los nombres inglés de Laravel y los locales usados
  /// por el modelo móvil.
  factory Habitacion.fromApiJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawNumero = json['number'] ?? json['room_number'] ?? json['numero'];
    final rawPiso = json['floor'] ?? json['floor_number'] ?? json['piso'];
    final rawTipo = json['room_type'] ?? json['type'] ?? json['tipo'];
    final rawEstado = json['status'] ?? json['estado'];
    final rawCamas = json['beds'] ?? json['bed_count'] ?? json['camas'];

    if (rawId == null ||
        rawNumero == null ||
        rawPiso == null ||
        rawTipo == null ||
        rawEstado == null) {
      throw const FormatException(
        'Faltan id, número, piso, tipo o estado en la habitación.',
      );
    }

    final tipoNombre = rawTipo is Map
        ? (rawTipo['name'] ?? rawTipo['type'] ?? rawTipo['nombre'])
        : rawTipo;
    final tipo = TipoCuarto.desdeNombre(tipoNombre.toString());

    final estadoTexto = rawEstado.toString().toLowerCase();
    final estado = switch (estadoTexto) {
      'disponible' || 'available' => EstadoHabitacion.disponible,
      'ocupada' || 'occupied' => EstadoHabitacion.ocupada,
      'ocupada_y_limpieza' ||
      'occupied_cleaning' => EstadoHabitacion.ocupadaYLimpieza,
      'limpieza' || 'cleaning' => EstadoHabitacion.limpieza,
      'reservada' || 'reserved' => EstadoHabitacion.reservada,
      'mantenimiento' || 'maintenance' => EstadoHabitacion.mantenimiento,
      _ => throw FormatException(
        'Estado de habitación no reconocido: $estadoTexto',
      ),
    };

    final rawStay =
        json['current_stay'] ??
        json['currentStay'] ??
        json['active_stay'] ??
        json['activeStay'];
    final stay = rawStay is Map
        ? Map<String, dynamic>.from(rawStay)
        : const <String, dynamic>{};
<<<<<<< Updated upstream
    final rawRate = stay['rate'];
    final rate = rawRate is Map
        ? Map<String, dynamic>.from(rawRate)
=======
    final rate = stay['rate'] is Map
        ? Map<String, dynamic>.from(stay['rate'] as Map)
>>>>>>> Stashed changes
        : const <String, dynamic>{};
    final tasks = json['tasks'] is List
        ? (json['tasks'] as List)
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList()
        : const <Map<String, dynamic>>[];
    final cleaningTask = tasks
        .where((task) => task['type'] == 'limpieza')
        .firstOrNull;
    final maintenanceTask = tasks
        .where((task) => task['type'] == 'mantenimiento')
        .firstOrNull;
    final stayGuest = stay['guest'];
    final rawGuest = json['guest'] ?? stayGuest ?? json['huesped'];
    final guestName = rawGuest is Map
        ? (rawGuest['name'] ?? rawGuest['nombre'])?.toString()
        : rawGuest?.toString();
    final stayGuestName = (stay['guest_name'] ?? json['guest_name'])
        ?.toString();
    final rawUpdatedAt = json['updated_at'] ?? json['updatedAt'];

    return Habitacion(
      rawNumero.toString(),
      int.tryParse(rawPiso.toString()) ??
          (throw const FormatException('El piso de habitación no es válido.')),
      tipo,
      estado,
      camas: int.tryParse(rawCamas?.toString() ?? '') ?? 1,
<<<<<<< Updated upstream
      huesped: guestName ?? stay['guest_name']?.toString(),
=======
      huesped: guestName ?? stayGuestName,
      huespedId: (stay['guest_id'] ?? (rawGuest is Map ? rawGuest['id'] : null))
          ?.toString(),
>>>>>>> Stashed changes
      huespedDocumento:
          (rawGuest is Map ? rawGuest['document'] : null)?.toString() ??
          stay['guest_document']?.toString(),
      huespedTelefono: (rawGuest is Map ? rawGuest['phone'] : null)?.toString(),
<<<<<<< Updated upstream
      huespedIdApi:
          (stay['guest_id'] ?? (rawGuest is Map ? rawGuest['id'] : null))
              ?.toString(),
      entradaEstadia: TiempoHotel.intentarDesdeApi(
        stay['check_in_at']?.toString(),
      ),
      salidaEstadia: TiempoHotel.intentarDesdeApi(
        stay['expected_checkout_at']?.toString(),
=======
      huespedCorreo: (rawGuest is Map ? rawGuest['email'] : null)?.toString(),
      entradaEstadia: DateTime.tryParse(stay['check_in_at']?.toString() ?? ''),
      salidaEstadia: DateTime.tryParse(
        stay['expected_checkout_at']?.toString() ?? '',
>>>>>>> Stashed changes
      ),
      nombreTarifa: rate['name']?.toString(),
      precioTarifa: double.tryParse(rate['price']?.toString() ?? ''),
      cantidadHuespedes: int.tryParse(stay['guests']?.toString() ?? ''),
      notasHabitacion: json['notes']?.toString(),
      notasEstadia: stay['notes']?.toString(),
      limpiezaSolicitada:
          json['cleaning_requested'] as bool? ??
          json['limpiezaSolicitada'] as bool? ??
          cleaningTask != null || estado == EstadoHabitacion.ocupadaYLimpieza,
      id: rawId.toString(),
      asignadoLimpiezaId:
          (json['assigned_cleaner_id'] ??
                  json['asignadoLimpiezaId'] ??
                  cleaningTask?['assigned_to'])
              ?.toString(),
      asignadoMantenimientoId:
          (json['assigned_maintenance_id'] ??
                  json['asignadoMantenimientoId'] ??
                  maintenanceTask?['assigned_to'])
              ?.toString(),
      reservaActivaId:
          (json['active_reservation_id'] ?? json['reservaActivaId'])
              ?.toString(),
      estadiaActivaId:
          (json['active_stay_id'] ?? json['estadiaActivaId'] ?? stay['id'])
              ?.toString(),
      updatedAt: DateTime.tryParse(rawUpdatedAt?.toString() ?? ''),
    );
  }

  factory Habitacion.fromJson(Map<String, dynamic> j) => Habitacion(
    j['numero'] as String,
    j['piso'] as int,
    TipoCuarto.desdeNombre(j['tipoCuarto'] as String? ?? 'comun'),
    EstadoHabitacion.desdeJson(j['estado'] as String? ?? 'disponible'),
    camas: j['camas'] as int? ?? 1,
    huesped: j['huesped'] as String?,
<<<<<<< Updated upstream
    huespedDocumento: j['huespedDocumento'] as String?,
    huespedTelefono: j['huespedTelefono'] as String?,
    huespedIdApi: j['huespedIdApi'] as String?,
    entradaEstadia: TiempoHotel.intentarDesdeApi(
      j['entradaEstadia'] as String?,
    ),
    salidaEstadia: TiempoHotel.intentarDesdeApi(j['salidaEstadia'] as String?),
=======
    huespedId: j['huespedId'] as String?,
    huespedDocumento: j['huespedDocumento'] as String?,
    huespedTelefono: j['huespedTelefono'] as String?,
    huespedCorreo: j['huespedCorreo'] as String?,
    entradaEstadia: DateTime.tryParse(j['entradaEstadia'] as String? ?? ''),
    salidaEstadia: DateTime.tryParse(j['salidaEstadia'] as String? ?? ''),
>>>>>>> Stashed changes
    nombreTarifa: j['nombreTarifa'] as String?,
    precioTarifa: (j['precioTarifa'] as num?)?.toDouble(),
    cantidadHuespedes: j['cantidadHuespedes'] as int?,
    notasHabitacion: j['notasHabitacion'] as String?,
    notasEstadia: j['notasEstadia'] as String?,
    limpiezaSolicitada: j['limpiezaSolicitada'] as bool? ?? false,
    rutaFoto: j['rutaFoto'] as String?,
    id: j['id'] as String?,
    descripcionLimpieza: j['descripcionLimpieza'] as String?,
    asignadoLimpiezaId: j['asignadoLimpiezaId'] as String?,
    asignadoMantenimientoId: j['asignadoMantenimientoId'] as String?,
    reservaActivaId: j['reservaActivaId'] as String?,
    estadiaActivaId: j['estadiaActivaId'] as String?,
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
  );
}
