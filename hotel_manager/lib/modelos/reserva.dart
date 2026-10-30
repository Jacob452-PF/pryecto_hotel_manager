enum EstadoReserva { activa, vencida, cancelada, convertida }

class Reserva {
  final String id;
  final String huespedId;
  final String habitacionId;
  final DateTime inicio;
  final DateTime fin;
  final EstadoReserva estado;
  final bool notificadaVencida;
  final DateTime createdAt;

  const Reserva({
    required this.id,
    required this.huespedId,
    required this.habitacionId,
    required this.inicio,
    required this.fin,
    this.estado = EstadoReserva.activa,
    this.notificadaVencida = false,
    required this.createdAt,
  });

  Reserva copyWith({EstadoReserva? estado, bool? notificadaVencida}) => Reserva(
    id: id,
    huespedId: huespedId,
    habitacionId: habitacionId,
    inicio: inicio,
    fin: fin,
    estado: estado ?? this.estado,
    notificadaVencida: notificadaVencida ?? this.notificadaVencida,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'huespedId': huespedId,
    'habitacionId': habitacionId,
    'inicio': inicio.toIso8601String(),
    'fin': fin.toIso8601String(),
    'estado': estado.name,
    'notificadaVencida': notificadaVencida,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
    id: j['id'] as String,
    huespedId: j['huespedId'] as String,
    habitacionId: j['habitacionId'] as String,
    inicio: DateTime.parse(j['inicio'] as String),
    fin: DateTime.parse(j['fin'] as String),
    estado: EstadoReserva.values.firstWhere(
      (e) => e.name == j['estado'],
      orElse: () => EstadoReserva.activa,
    ),
    notificadaVencida: j['notificadaVencida'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
