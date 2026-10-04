import '../modelos/habitacion.dart';
import '../modelos/tipo_cuarto.dart';

// Datos de ejemplo: reemplázalos por tu API / base de datos.
const habitacionesEjemplo = <Habitacion>[
  Habitacion('101', 1, TipoCuarto.individual, EstadoHabitacion.disponible),
  Habitacion('102', 1, TipoCuarto.matrimonial, EstadoHabitacion.ocupada, huesped: 'María López'),
  Habitacion('103', 1, TipoCuarto.individual, EstadoHabitacion.limpieza),
  Habitacion('104', 1, TipoCuarto.familiar, EstadoHabitacion.ocupada, camas: 2, huesped: 'Carlos Hernández'),
  Habitacion('105', 1, TipoCuarto.familiar, EstadoHabitacion.disponible, camas: 3),
  Habitacion('201', 2, TipoCuarto.familiar, EstadoHabitacion.mantenimiento, camas: 2),
  Habitacion('202', 2, TipoCuarto.matrimonial, EstadoHabitacion.disponible),
  Habitacion('203', 2, TipoCuarto.familiar, EstadoHabitacion.ocupada, camas: 2, huesped: 'Ana Martínez'),
  Habitacion('204', 2, TipoCuarto.familiar, EstadoHabitacion.disponible, camas: 2),
  Habitacion('205', 2, TipoCuarto.familiar, EstadoHabitacion.mantenimiento, camas: 4),
  Habitacion('301', 3, TipoCuarto.individual, EstadoHabitacion.disponible),
  Habitacion('302', 3, TipoCuarto.familiar, EstadoHabitacion.ocupada, camas: 3, huesped: 'José Ramírez'),
  Habitacion('303', 3, TipoCuarto.familiar, EstadoHabitacion.disponible, camas: 4),
  Habitacion('304', 3, TipoCuarto.matrimonial, EstadoHabitacion.limpieza),
];