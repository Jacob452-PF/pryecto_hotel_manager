enum MetodoAbono { efectivo, tarjeta, transferencia }

class Abono {
  final String id;
  final String facturaId;
  final double monto;
  final MetodoAbono metodo;
  final String usuarioId;
  final String cajaId;
  final DateTime createdAt;
  const Abono({
    required this.id,
    required this.facturaId,
    required this.monto,
    required this.metodo,
    required this.usuarioId,
    required this.cajaId,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'facturaId': facturaId,
    'monto': monto,
    'metodo': metodo.name,
    'usuarioId': usuarioId,
    'cajaId': cajaId,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Abono.fromJson(Map<String, dynamic> j) => Abono(
    id: j['id'] as String,
    facturaId: j['facturaId'] as String,
    monto: (j['monto'] as num).toDouble(),
    metodo: MetodoAbono.values.firstWhere(
      (m) => m.name == j['metodo'],
      orElse: () => MetodoAbono.efectivo,
    ),
    usuarioId: j['usuarioId'] as String,
    cajaId: j['cajaId'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
