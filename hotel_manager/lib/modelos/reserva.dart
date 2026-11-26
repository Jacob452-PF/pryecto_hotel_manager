import 'tipo_cuarto.dart';
import 'tarifa.dart';
import '../utilidades/tiempo_hotel.dart';

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
  final String? tarifaNombre;
  final int cantidad;
  final DateTime inicio;
  final DateTime fin;
  final double total;
  final double montoAbonado;
  final double saldoPendiente;
  final EstadoReserva estado;
  final bool notificadaVencida;
  final DateTime createdAt;

  const Reserva({
    required this.id,
    required this.huespedId,
    this.habitacionId,
    this.tipoCuarto = TipoCuarto.comun,
    this.camas = 1,
    this.tarifa = TipoTarifa.porNoche,
    this.tarifaNombre,
    this.cantidad = 1,
    required this.inicio,
    required this.fin,
    this.total = 0,
    this.montoAbonado = 0,
    this.saldoPendiente = 0,
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
    tarifaNombre: tarifaNombre,
    cantidad: cantidad,
    inicio: inicio,
    fin: fin,
    total: total,
    montoAbonado: montoAbonado,
    saldoPendiente: saldoPendiente,
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
    'tarifaNombre': tarifaNombre,
    'cantidad': cantidad,
    'inicio': inicio.toIso8601String(),
    'fin': fin.toIso8601String(),
    'total': total,
    'montoAbonado': montoAbonado,
    'saldoPendiente': saldoPendiente,
    'estado': estado.name,
    'notificadaVencida': notificadaVencida,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
    id: j['id'] as String,
    huespedId: j['huespedId'] as String,
    habitacionId: j['habitacionId'] as String?,
    tipoCuarto: TipoCuarto.desdeNombre(j['tipoCuarto'] as String? ?? 'comun'),
    camas: j['camas'] as int? ?? 1,
    tarifa: TipoTarifa.values.firstWhere(
      (e) => e.name == j['tarifa'],
      orElse: () => TipoTarifa.porNoche,
    ),
    tarifaNombre: j['tarifaNombre'] as String?,
    cantidad: j['cantidad'] as int? ?? 1,
    inicio: DateTime.parse(j['inicio'] as String),
    fin: DateTime.parse(j['fin'] as String),
    total: (j['total'] as num?)?.toDouble() ?? 0,
    montoAbonado: (j['montoAbonado'] as num?)?.toDouble() ?? 0,
    saldoPendiente: (j['saldoPendiente'] as num?)?.toDouble() ?? 0,
    estado: EstadoReserva.values.firstWhere(
      (e) => e.name == j['estado'],
      orElse: () => EstadoReserva.activa,
    ),
    notificadaVencida: j['notificadaVencida'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  factory Reserva.fromApiJson(Map<String, dynamic> json) {
    final room = json['room'] is Map
        ? Map<String, dynamic>.from(json['room'] as Map)
        : null;
    final rate = json['rate'] is Map
        ? Map<String, dynamic>.from(json['rate'] as Map)
        : null;
    final guestId = json['guest_id'] ?? (json['guest'] as Map?)?['id'];
    final checkIn = TiempoHotel.desdeApi(json['check_in_at'].toString());
    final checkout = TiempoHotel.desdeApi(
      json['expected_checkout_at'].toString(),
    );
    final hours = int.tryParse(rate?['hours']?.toString() ?? '') ?? 12;
    final status = json['status']?.toString();

    return Reserva(
      id: json['id'].toString(),
      huespedId: guestId.toString(),
      habitacionId: (room?['number'] ?? json['room_id'])?.toString(),
      tipoCuarto: TipoCuarto.desdeNombre(
        (room?['type'] ?? json['room_type'] ?? 'estandar').toString(),
      ),
      camas: int.tryParse((room?['beds'] ?? json['beds'] ?? 1).toString()) ?? 1,
      tarifa: hours <= 6 ? TipoTarifa.porHora : TipoTarifa.porNoche,
      tarifaNombre: rate?['name']?.toString(),
      cantidad: int.tryParse(json['rate_units']?.toString() ?? '') ?? 1,
      inicio: checkIn,
      fin: checkout,
      total:
          double.tryParse(
            (json['agreed_price'] ?? rate?['price'] ?? 0).toString(),
          ) ??
          0,
      montoAbonado: double.tryParse(json['paid_amount']?.toString() ?? '') ?? 0,
      saldoPendiente:
          double.tryParse(json['balance']?.toString() ?? '') ??
          double.tryParse((json['agreed_price'] ?? 0).toString()) ??
          0,
      estado: switch (status) {
        'cancelada' => EstadoReserva.cancelada,
        'convertida' => EstadoReserva.convertida,
        _
            when status == 'vencida' ||
                checkout.isBefore(TiempoHotel.ahoraUtc()) =>
          EstadoReserva.vencida,
        _ => EstadoReserva.activa,
      },
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? checkIn,
    );
  }
}
