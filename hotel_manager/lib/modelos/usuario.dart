/// Datos del empleado que tiene la sesión abierta.
class Usuario {
  final String nombre;
  final String cargo;
  final int? edad;

  const Usuario({required this.nombre, required this.cargo, this.edad});
}
