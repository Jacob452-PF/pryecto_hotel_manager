/// Filtros de fecha del historial: Todo, Hoy, Esta semana, Este mes.
enum PeriodoHistorial {
  todo('Todo'),
  hoy('Hoy'),
  semana('Esta semana'),
  mes('Este mes');

  final String etiqueta;
  const PeriodoHistorial(this.etiqueta);

  bool contiene(DateTime fecha, DateTime ahora) {
    switch (this) {
      case PeriodoHistorial.todo:
        return true;
      case PeriodoHistorial.hoy:
        return fecha.year == ahora.year &&
            fecha.month == ahora.month &&
            fecha.day == ahora.day;
      case PeriodoHistorial.semana:
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        final lunes = hoy.subtract(Duration(days: ahora.weekday - 1));
        return !fecha.isBefore(lunes);
      case PeriodoHistorial.mes:
        return fecha.year == ahora.year && fecha.month == ahora.month;
    }
  }
}
