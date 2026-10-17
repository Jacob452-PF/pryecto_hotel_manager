const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// 168.4 → "$168.40"
String dinero(double valor) => '\$${valor.toStringAsFixed(2)}';

/// "11 de agosto de 2026"
String fechaLarga(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// "02:15 p.m."
String hora(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  final sufijo = d.hour >= 12 ? 'p.m.' : 'a.m.';
  return '${h.toString().padLeft(2, '0')}:$min $sufijo';
}

/// "11 de agosto de 2026 - 02:15 p.m."
String fechaHora(DateTime d) => '${fechaLarga(d)} - ${hora(d)}';
