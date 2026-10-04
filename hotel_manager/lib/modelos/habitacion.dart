import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import 'tipo_cuarto.dart';

enum EstadoHabitacion {
  disponible('Disponible', ColoresApp.disponible, Icons.check_circle),
  ocupada('Ocupada', ColoresApp.ocupada, Icons.bed),
  limpieza('En limpieza', ColoresApp.limpieza, Icons.cleaning_services),
  mantenimiento('Mantenimiento', ColoresApp.mantenimiento, Icons.build);

  const EstadoHabitacion(this.etiqueta, this.color, this.icono);
  final String etiqueta;
  final Color color;
  final IconData icono;
}

class Habitacion {
  final String numero;
  final int piso;

  /// Matrimonial, individual o familiar.
  final TipoCuarto tipoCuarto;
  final EstadoHabitacion estado;

  /// Cantidad de camas. Las familiares tienen 2, 3 o 4; las demás, 1.
  final int camas;

  /// Nombre del huésped que la ocupa (solo si el estado es ocupada).
  final String? huesped;

  /// Ruta de la foto de la habitación. Es null hasta que se tome la foto
  /// al agregar la habitación al catálogo.
  final String? rutaFoto;

  const Habitacion(
    this.numero,
    this.piso,
    this.tipoCuarto,
    this.estado, {
    this.camas = 1,
    this.huesped,
    this.rutaFoto,
  });

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
      rutaFoto: rutaFoto,
    );
  }
}