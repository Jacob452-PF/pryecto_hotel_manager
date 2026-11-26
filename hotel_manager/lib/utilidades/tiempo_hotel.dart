/// Conversión de fechas para la zona configurada por el servidor.
/// America/El_Salvador usa UTC-06:00 y no aplica horario de verano.
class TiempoHotel {
  TiempoHotel._();

  static const zonaHoraria = 'America/El_Salvador';
  static const _desfaseElSalvador = Duration(hours: -6);

  /// Normaliza ISO del API a UTC aunque el dispositivo use otra zona.
  static DateTime desdeApi(String valor) {
    final parsed = DateTime.parse(valor);
    final traeZona = RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(valor.trim());
    if (traeZona) return parsed.toUtc();
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).subtract(_desfaseElSalvador);
  }

  static DateTime ahoraUtc() => DateTime.now().toUtc();

  static DateTime? intentarDesdeApi(String? valor) =>
      valor == null || valor.isEmpty ? null : desdeApi(valor);

  /// Los componentes del resultado representan el reloj de pared de El Salvador.
  static DateTime relojElSalvador(DateTime instante) =>
      instante.toUtc().add(_desfaseElSalvador);

  static String duracion(Duration duracion) {
    final segundos = duracion.inSeconds.abs();
    final dias = segundos ~/ Duration.secondsPerDay;
    final horas = (segundos ~/ Duration.secondsPerHour) % 24;
    final minutos = (segundos ~/ Duration.secondsPerMinute) % 60;
    final resto = segundos % 60;
    final reloj =
        '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${resto.toString().padLeft(2, '0')}';
    return dias > 0 ? '${dias}d $reloj' : reloj;
  }
}
