import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
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

  /// Matrimonial, individual o familiar.
  final TipoCuarto tipoCuarto;
  final EstadoHabitacion estado;

  /// Cantidad de camas. Las familiares tienen 2, 3 o 4; las demás, 1.
  final int camas;

  /// Nombre del huésped que la ocupa (solo si el estado es ocupada).
  final String? huesped;

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
    'limpiezaSolicitada': limpiezaSolicitada,
    'rutaFoto': rutaFoto,
    'descripcionLimpieza': descripcionLimpieza,
    'asignadoLimpiezaId': asignadoLimpiezaId,
    'asignadoMantenimientoId': asignadoMantenimientoId,
    'reservaActivaId': reservaActivaId,
    'estadiaActivaId': estadiaActivaId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Habitacion.fromJson(Map<String, dynamic> j) => Habitacion(
    j['numero'] as String,
    j['piso'] as int,
    TipoCuarto.values.firstWhere(
      (t) => t.name == j['tipoCuarto'],
      orElse: () => TipoCuarto.individual,
    ),
    EstadoHabitacion.desdeJson(j['estado'] as String? ?? 'disponible'),
    camas: j['camas'] as int? ?? 1,
    huesped: j['huesped'] as String?,
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
