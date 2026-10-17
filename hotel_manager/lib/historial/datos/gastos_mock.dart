import '../modelos/turno_caja.dart';

/// Gastos de ejemplo del turno (todavía no hay pantalla para registrarlos).
/// Después se reemplaza por los gastos reales.
List<GastoTurno> crearGastosMock() {
  return [
    const GastoTurno(CategoriaGasto.alimentos, 'Compras de cocina', 18.00),
    const GastoTurno(CategoriaGasto.aseo, 'Productos de limpieza', 6.00),
    const GastoTurno(
      CategoriaGasto.mantenimiento,
      'Reparación de equipo',
      6.00,
    ),
  ];
}
