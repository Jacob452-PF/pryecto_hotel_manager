class Huesped {
  final String id;
  final String nombre;
  final String dui;
  final String telefono;
  final String? email;
  final DateTime createdAt;

  const Huesped({
    required this.id,
    required this.nombre,
    required this.dui,
    required this.telefono,
    this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'dui': dui,
    'telefono': telefono,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Huesped.fromJson(Map<String, dynamic> j) => Huesped(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    dui: j['dui'] as String,
    telefono: j['telefono'] as String,
    email: j['email'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
