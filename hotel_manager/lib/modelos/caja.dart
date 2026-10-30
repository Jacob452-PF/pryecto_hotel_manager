const Map<String, double> denominacionesUsd = {
  '1c': 0.01,
  '5c': 0.05,
  '10c': 0.10,
  '25c': 0.25,
  r'$1': 1,
  r'$2': 2,
  r'$5': 5,
  r'$10': 10,
  r'$20': 20,
  r'$50': 50,
  r'$100': 100,
};

class DesgloseEfectivo {
  /// Importe total contado por denominación, no número de monedas/billetes.
  final Map<String, double> valores;
  DesgloseEfectivo({Map<String, double>? valores})
    : valores = Map.unmodifiable({
        for (final key in denominacionesUsd.keys)
          key: (((valores?[key] ?? 0) * 100).round() / 100),
      });
  double get total =>
      (valores.values.fold<double>(0, (sum, value) => sum + value) * 100)
          .round() /
      100;
  Map<String, dynamic> toJson() => {
    'valores': Map<String, dynamic>.from(valores),
  };
  factory DesgloseEfectivo.fromJson(Map<String, dynamic> j) {
    final raw = (j['valores'] as Map?)?.cast<String, dynamic>();
    if (raw != null) {
      return DesgloseEfectivo(
        valores: {
          for (final k in denominacionesUsd.keys)
            k: (raw[k] as num?)?.toDouble() ?? 0,
        },
      );
    }
    // Compatibilidad con cajas guardadas cuando se ingresaba cantidad de piezas.
    return DesgloseEfectivo(
      valores: {
        for (final e in denominacionesUsd.entries)
          e.key: e.value * ((j[e.key] as num?)?.toDouble() ?? 0),
      },
    );
  }
}

class Caja {
  final String id;
  final String usuarioId;
  final DateTime aperturaAt;
  final DateTime? cierreAt;
  final double montoApertura;
  final DesgloseEfectivo desgloseApertura;
  final double? montoCierre;
  final DesgloseEfectivo? desgloseCierre;
  final double? diferencia;
  final bool confirmada;
  final String? notas;

  const Caja({
    required this.id,
    required this.usuarioId,
    required this.aperturaAt,
    this.cierreAt,
    required this.montoApertura,
    required this.desgloseApertura,
    this.montoCierre,
    this.desgloseCierre,
    this.diferencia,
    this.confirmada = false,
    this.notas,
  });
  bool get abierta => cierreAt == null;
  Caja cerrar({
    required DateTime fecha,
    required DesgloseEfectivo desglose,
    double? diferencia,
    required bool confirmada,
    String? notas,
  }) => Caja(
    id: id,
    usuarioId: usuarioId,
    aperturaAt: aperturaAt,
    cierreAt: fecha,
    montoApertura: montoApertura,
    desgloseApertura: desgloseApertura,
    montoCierre: desglose.total,
    desgloseCierre: desglose,
    diferencia: diferencia,
    confirmada: confirmada,
    notas: notas,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioId': usuarioId,
    'aperturaAt': aperturaAt.toIso8601String(),
    'cierreAt': cierreAt?.toIso8601String(),
    'montoApertura': montoApertura,
    'desgloseApertura': desgloseApertura.toJson(),
    'montoCierre': montoCierre,
    'desgloseCierre': desgloseCierre?.toJson(),
    'diferencia': diferencia,
    'confirmada': confirmada,
    'notas': notas,
  };
  factory Caja.fromJson(Map<String, dynamic> j) => Caja(
    id: j['id'] as String,
    usuarioId: j['usuarioId'] as String,
    aperturaAt: DateTime.parse(j['aperturaAt'] as String),
    cierreAt: DateTime.tryParse(j['cierreAt'] as String? ?? ''),
    montoApertura: (j['montoApertura'] as num).toDouble(),
    desgloseApertura: DesgloseEfectivo.fromJson(
      (j['desgloseApertura'] as Map?)?.cast<String, dynamic>() ?? {},
    ),
    montoCierre: (j['montoCierre'] as num?)?.toDouble(),
    desgloseCierre: (j['desgloseCierre'] as Map?) == null
        ? null
        : DesgloseEfectivo.fromJson(
            (j['desgloseCierre'] as Map).cast<String, dynamic>(),
          ),
    diferencia: (j['diferencia'] as num?)?.toDouble(),
    confirmada: (j['confirmada'] as bool?) ?? false,
    notas: j['notas'] as String?,
  );
}
