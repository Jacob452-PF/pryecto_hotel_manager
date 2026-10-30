enum RolUsuario { recepcion, limpieza, mantenimiento, admin }

/// Identidad local. `cargo` y `edad` se mantienen para la UI heredada.
class Usuario {
  final String id;
  final String nombre;
  final String dui;
  final String telefono;
  final RolUsuario rol;
  final bool activo;
  final String username;
  final String passwordHash;
  final DateTime createdAt;
  final String cargo;
  final int? edad;

  Usuario({
    required this.nombre,
    String? cargo,
    this.edad,
    this.id = '',
    this.dui = '',
    this.telefono = '',
    this.rol = RolUsuario.recepcion,
    this.activo = true,
    this.username = '',
    this.passwordHash = '',
    DateTime? createdAt,
  }) : cargo = cargo ?? 'Recepción',
       createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'dui': dui,
    'telefono': telefono,
    'rol': rol.name,
    'activo': activo,
    'username': username,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    dui: json['dui'] as String? ?? '',
    telefono: json['telefono'] as String? ?? '',
    rol: RolUsuario.values.firstWhere(
      (r) => r.name == json['rol'],
      orElse: () => RolUsuario.recepcion,
    ),
    activo: json['activo'] as bool? ?? true,
    username: json['username'] as String? ?? '',
    passwordHash: json['passwordHash'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
