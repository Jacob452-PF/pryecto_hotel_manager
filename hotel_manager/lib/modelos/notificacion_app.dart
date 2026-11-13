enum SeveridadNotificacion { urgente, leve }

class NotificacionApp {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final SeveridadNotificacion severidad;
  final bool leida;
  final String? habitacion;

  const NotificacionApp({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.severidad,
    this.leida = false,
    this.habitacion,
  });

  NotificacionApp copyWith({bool? leida}) => NotificacionApp(
    id: id,
    titulo: titulo,
    mensaje: mensaje,
    fecha: fecha,
    severidad: severidad,
    leida: leida ?? this.leida,
    habitacion: habitacion,
  );
}
