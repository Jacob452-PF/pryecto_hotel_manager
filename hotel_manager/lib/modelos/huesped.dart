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

  /// Convierte los nombres usados por la API Laravel al modelo de la app.
  factory Huesped.fromApiJson(Map<String, dynamic> json) {
    if (json['id'] == null ||
        json['name'] == null ||
        json['document'] == null ||
        json['phone'] == null) {
      throw const FormatException(
        'Faltan id, name, document o phone en el huésped.',
      );
    }
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    return Huesped(
      id: json['id'].toString(),
      nombre: (json['name'] ?? '').toString(),
      dui: (json['document'] ?? '').toString(),
      telefono: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      createdAt:
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toApiJson() => {
    'name': nombre,
    'document': dui,
    'phone': telefono,
    if (email != null && email!.isNotEmpty) 'email': email,
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
