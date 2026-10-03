import 'package:flutter/material.dart';
import '../tema/colores_app.dart';

enum TipoHabitacion { estandar, especial }

enum EstadoHabitacion {
  disponible('Disponible', ColoresApp.disponible, Icons.check_circle),
  ocupada('Ocupada', ColoresApp.ocupadaEstandar, Icons.bed),
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
  final TipoHabitacion tipo;
  final EstadoHabitacion estado;
  const Habitacion(this.numero, this.piso, this.tipo, this.estado);
}