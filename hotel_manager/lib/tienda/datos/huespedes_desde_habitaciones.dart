import '../../modelos/habitacion.dart';
import '../modelos/huesped_tienda.dart';

/// Convierte las habitaciones OCUPADAS (con huésped) en la lista de personas
/// a las que se les puede cargar una compra en el carrito.
///
/// Es el único lugar donde la tienda lee el modelo `Habitacion`: si cambian
/// los nombres de los campos, solo hay que ajustarlos aquí.
List<HuespedTienda> huespedesDeHabitaciones(List<Habitacion> habitaciones) {
  return habitaciones
      .where(
        (h) =>
            h.estado == EstadoHabitacion.ocupada &&
            (h.huesped ?? '').isNotEmpty,
      )
      .map(
        (h) => HuespedTienda(
          id: h.numero,
          nombre: h.huesped ?? '',
          habitacion: h.numero,
        ),
      )
      .toList();
}
