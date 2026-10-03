import '../modelos/habitacion.dart';

// Datos de ejemplo: reemplázalos por tu API / base de datos.
const habitacionesEjemplo = <Habitacion>[
  Habitacion('101', 1, TipoHabitacion.estandar, EstadoHabitacion.disponible),
  Habitacion('102', 1, TipoHabitacion.estandar, EstadoHabitacion.ocupada),
  Habitacion('103', 1, TipoHabitacion.estandar, EstadoHabitacion.limpieza),
  Habitacion('104', 1, TipoHabitacion.especial, EstadoHabitacion.ocupada),
  Habitacion('105', 1, TipoHabitacion.especial, EstadoHabitacion.disponible),
  Habitacion('201', 2, TipoHabitacion.estandar, EstadoHabitacion.mantenimiento),
  Habitacion('202', 2, TipoHabitacion.estandar, EstadoHabitacion.disponible),
  Habitacion('203', 2, TipoHabitacion.estandar, EstadoHabitacion.ocupada),
  Habitacion('204', 2, TipoHabitacion.especial, EstadoHabitacion.limpieza),
  Habitacion('205', 2, TipoHabitacion.especial, EstadoHabitacion.mantenimiento),
  Habitacion('301', 3, TipoHabitacion.estandar, EstadoHabitacion.disponible),
  Habitacion('302', 3, TipoHabitacion.especial, EstadoHabitacion.ocupada),
];