/// Huésped al que se le puede cargar una compra.
/// Cuando tengan base de datos, se llena con los huéspedes de habitaciones ocupadas.
class HuespedTienda {
  final String id;
  final String nombre;
  final String habitacion;

  const HuespedTienda({
    required this.id,
    required this.nombre,
    required this.habitacion,
  });
}
