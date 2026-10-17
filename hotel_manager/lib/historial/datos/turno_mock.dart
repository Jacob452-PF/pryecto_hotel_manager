import '../modelos/turno_caja.dart';

/// Turno de ejemplo que se muestra en "Cierre de caja".
/// Después se reemplaza por las ventas y gastos reales del turno.
TurnoCaja crearTurnoMock() {
  return const TurnoCaja(
    usuario: 'Jose A.',
    ventas: [
      VentaTurno(TipoVenta.habitaciones, 3, 98.00),
      VentaTurno(TipoVenta.servicios, 4, 20.90),
      VentaTurno(TipoVenta.productos, 5, 6.00),
    ],
    gastos: [
      GastoTurno(CategoriaGasto.alimentos, 'Compras de cocina', 18.00),
      GastoTurno(CategoriaGasto.aseo, 'Productos de limpieza', 6.00),
      GastoTurno(CategoriaGasto.mantenimiento, 'Reparación de equipo', 6.00),
    ],
    habitacionesOcupadas: 10,
    habitacionesTotal: 40,
  );
}
