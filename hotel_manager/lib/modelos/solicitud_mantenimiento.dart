enum EstadoSolicitudMantenimiento {
  pendiente,
  aceptada,
  asignada,
  en_proceso,
  resuelta,
}

class SolicitudMantenimiento {
  final String id;
  final String habitacionId;
  final String descripcion;
  final EstadoSolicitudMantenimiento estado;
  final String? asignadoA;
  final DateTime createdAt;
  final DateTime? resueltaAt;

  const SolicitudMantenimiento({
    required this.id,
    required this.habitacionId,
    required this.descripcion,
    this.estado = EstadoSolicitudMantenimiento.pendiente,
    this.asignadoA,
    required this.createdAt,
    this.resueltaAt,
  });
  SolicitudMantenimiento copyWith({
    EstadoSolicitudMantenimiento? estado,
    String? asignadoA,
    DateTime? resueltaAt,
  }) => SolicitudMantenimiento(
    id: id,
    habitacionId: habitacionId,
    descripcion: descripcion,
    estado: estado ?? this.estado,
    asignadoA: asignadoA ?? this.asignadoA,
    createdAt: createdAt,
    resueltaAt: resueltaAt ?? this.resueltaAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'habitacionId': habitacionId,
    'descripcion': descripcion,
    'estado': estado.name,
    'asignadoA': asignadoA,
    'createdAt': createdAt.toIso8601String(),
    'resueltaAt': resueltaAt?.toIso8601String(),
  };
  factory SolicitudMantenimiento.fromJson(Map<String, dynamic> j) =>
      SolicitudMantenimiento(
        id: j['id'] as String,
        habitacionId: j['habitacionId'] as String,
        descripcion: j['descripcion'] as String,
        estado: EstadoSolicitudMantenimiento.values.firstWhere(
          (e) => e.name == j['estado'],
          orElse: () => EstadoSolicitudMantenimiento.pendiente,
        ),
        asignadoA: j['asignadoA'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        resueltaAt: DateTime.tryParse(j['resueltaAt'] as String? ?? ''),
      );
}
