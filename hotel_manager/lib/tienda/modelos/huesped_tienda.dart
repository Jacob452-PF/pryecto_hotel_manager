/// Huésped al que se le puede cargar una compra.
/// Cuando tengan base de datos, se llena con los huéspedes de habitaciones ocupadas.
class HuespedTienda {
  final String id;
  final String nombre;
  final String habitacion;
  final String? estadiaIdApi;
  final String? huespedIdApi;
<<<<<<< Updated upstream
  final String? documento;
  final String? telefono;
=======
>>>>>>> Stashed changes

  const HuespedTienda({
    required this.id,
    required this.nombre,
    required this.habitacion,
    this.estadiaIdApi,
    this.huespedIdApi,
<<<<<<< Updated upstream
    this.documento,
    this.telefono,
=======
>>>>>>> Stashed changes
  });
}
