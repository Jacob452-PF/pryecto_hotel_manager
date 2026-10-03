/// Muestra un monto en dólares con dos decimales. Ejemplo: $25.00
String formatearDinero(double monto) => '\$${monto.toStringAsFixed(2)}';