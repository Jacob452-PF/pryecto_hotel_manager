import '../../modelos/habitacion.dart';
import '../modelos/huesped_tienda.dart';

<<<<<<< Updated upstream
/// Convierte las habitaciones con estadía activa en destinos para cargar
/// consumos, incluidas las estadías sin huésped identificado.
=======
/// Convierte las habitaciones ocupadas con estadía activa en destinos de cargo.
>>>>>>> Stashed changes
///
/// Es el único lugar donde la tienda lee el modelo `Habitacion`: si cambian
/// los nombres de los campos, solo hay que ajustarlos aquí.
List<HuespedTienda> huespedesDeHabitaciones(List<Habitacion> habitaciones) {
  return habitaciones
      .where(
        (h) =>
            (h.estado == EstadoHabitacion.ocupada ||
                h.estado == EstadoHabitacion.ocupadaYLimpieza) &&
            h.estadiaActivaId != null,
      )
      .map(
        (h) => HuespedTienda(
          id: h.estadiaActivaId!,
          nombre: h.huesped?.trim().isNotEmpty == true
              ? h.huesped!.trim()
              : 'Cliente sin registrar',
          habitacion: h.numero,
          estadiaIdApi: h.estadiaActivaId,
<<<<<<< Updated upstream
          huespedIdApi: h.huespedIdApi,
          documento: h.huespedDocumento,
          telefono: h.huespedTelefono,
=======
          huespedIdApi: h.huespedId,
>>>>>>> Stashed changes
        ),
      )
      .toList();
}
