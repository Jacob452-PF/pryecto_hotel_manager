import 'tipo_cuarto.dart';
import 'tarifa.dart';

enum EstadoReserva { activa, vencida, cancelada, convertida }

class Reserva {
  final String id;
  final String huespedId;
  /// Las solicitudes nuevas no asignan habitación; se conserva nullable para
  /// leer reservas antiguas que sí guardaban un número.
  final String? habitacionId;
  final TipoCuarto tipoCuarto;
  final int camas;
  final TipoTarifa tarifa;
  final int cantidad;
  final DateTime inicio;
  final DateTime fin;
  final double total;
  final EstadoReserva estado;
  final bool notificadaVencida;
  final DateTime createdAt;

  const Reserva({
    required this.id,
    required this.huespedId,
    this.habitacionId,
    this.tipoCuarto = TipoCuarto.matrimonial,
    this.camas = 1,
    this.tarifa = TipoTarifa.porNoche,
    this.cantidad = 1,
    required this.inicio,
    required this.fin,
    this.total = 0,
    this.estado = EstadoReserva.activa,
    this.notificadaVencida = false,
    required this.createdAt,
  });

  Reserva copyWith({EstadoReserva? estado, bool? notificadaVencida}) => Reserva(
    id: id,
    huespedId: huespedId,
    habitacionId: habitacionId,
    tipoCuarto: tipoCuarto,
    camas: camas,
    tarifa: tarifa,
    cantidad: cantidad,
    inicio: inicio,
    fin: fin,
    total: total,
    estado: estado ?? this.estado,
    notificadaVencida: notificadaVencida ?? this.notificadaVencida,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'huespedId': huespedId,
    'habitacionId': habitacionId,
    'tipoCuarto': tipoCuarto.name,
    'camas': camas,
    'tarifa': tarifa.name,
    'cantidad': cantidad,
    'inicio': inicio.toIso8601String(),
    'fin': fin.toIso8601String(),
    'total': total,
    'estado': estado.name,
    'notificadaVencida': notificadaVencida,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
    id: j['id'] as String,
    huespedId: j['huespedId'] as String,
    habitacionId: j['habitacionId'] as String?,
    tipoCuarto: TipoCuarto.values.firstWhere(
      (e) => e.name == j['tipoCuarto'],
      orElse: () => TipoCuarto.matrimonial,
    ),
    camas: j['camas'] as int? ?? 1,
    tarifa: TipoTarifa.values.firstWhere(
      (e) => e.name == j['tarifa'],
      orElse: () => TipoTarifa.porNoche,
    ),
    cantidad: j['cantidad'] as int? ?? 1,
    inicio: DateTime.parse(j['inicio'] as String),
    fin: DateTime.parse(j['fin'] as String),
    total: (j['total'] as num?)?.toDouble() ?? 0,
    estado: EstadoReserva.values.firstWhere(
      (e) => e.name == j['estado'],
      orElse: () => EstadoReserva.activa,
    ),
    notificadaVencida: j['notificadaVencida'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
