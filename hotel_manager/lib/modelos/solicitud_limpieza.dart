enum OrigenLimpieza { huesped, recepcion, admin }

enum EstadoSolicitudLimpieza {
  pendiente,
  aceptada,
  asignada,
  en_proceso,
  lista,
}

class SolicitudLimpieza {
  final String id;
  final String habitacionId;
  final OrigenLimpieza origen;
  final String? descripcion;
  final EstadoSolicitudLimpieza estado;
  final String? asignadoA;
  final DateTime createdAt;
  final DateTime? cerradaAt;

  const SolicitudLimpieza({
    required this.id,
    required this.habitacionId,
    required this.origen,
    this.descripcion,
    this.estado = EstadoSolicitudLimpieza.pendiente,
    this.asignadoA,
    required this.createdAt,
    this.cerradaAt,
  });

  SolicitudLimpieza copyWith({
    EstadoSolicitudLimpieza? estado,
    String? asignadoA,
    DateTime? cerradaAt,
  }) => SolicitudLimpieza(
    id: id,
    habitacionId: habitacionId,
    origen: origen,
    descripcion: descripcion,
    estado: estado ?? this.estado,
    asignadoA: asignadoA ?? this.asignadoA,
    createdAt: createdAt,
    cerradaAt: cerradaAt ?? this.cerradaAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'habitacionId': habitacionId,
    'origen': origen.name,
    'descripcion': descripcion,
    'estado': estado.name,
    'asignadoA': asignadoA,
    'createdAt': createdAt.toIso8601String(),
    'cerradaAt': cerradaAt?.toIso8601String(),
  };
  factory SolicitudLimpieza.fromJson(Map<String, dynamic> j) =>
      SolicitudLimpieza(
        id: j['id'] as String,
        habitacionId: j['habitacionId'] as String,
        origen: OrigenLimpieza.values.firstWhere(
          (e) => e.name == j['origen'],
          orElse: () => OrigenLimpieza.recepcion,
        ),
        descripcion: j['descripcion'] as String?,
        estado: EstadoSolicitudLimpieza.values.firstWhere(
          (e) => e.name == j['estado'],
          orElse: () => EstadoSolicitudLimpieza.pendiente,
        ),
        asignadoA: j['asignadoA'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        cerradaAt: DateTime.tryParse(j['cerradaAt'] as String? ?? ''),
      );
}
