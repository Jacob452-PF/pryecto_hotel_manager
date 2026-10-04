/// Muestra un monto en dólares con dos decimales. Ejemplo: $25.00
String formatearDinero(double monto) => '\$${monto.toStringAsFixed(2)}';

/// Fecha y hora como 04/10/2026 15:30
String formatearFechaHora(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

/// DUI de 9 dígitos como 12345678-9
String formatearDui(String dui) =>
    dui.length == 9 ? '${dui.substring(0, 8)}-${dui.substring(8)}' : dui;

/// Teléfono de 8 dígitos como 7000-0000
String formatearTelefono(String telefono) => telefono.length == 8
    ? '${telefono.substring(0, 4)}-${telefono.substring(4)}'
    : telefono;