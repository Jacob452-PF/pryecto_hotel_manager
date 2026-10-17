/// Una línea de consumo (producto o servicio cobrado a un cliente).
class LineaConsumo {
  final String nombre;
  final double precio;
  final int cantidad;

  const LineaConsumo(this.nombre, this.precio, [this.cantidad = 1]);

  double get importe => precio * cantidad;
}

/// Todo lo que consumió un cliente durante el turno.
class ConsumoCliente {
  final String cliente;

  /// Etiqueta que se muestra a la derecha, por ejemplo "#A2".
  final String codigo;
  final List<LineaConsumo> lineas;

  const ConsumoCliente({
    required this.cliente,
    required this.codigo,
    required this.lineas,
  });

  int get articulos => lineas.fold(0, (s, l) => s + l.cantidad);
  double get total => lineas.fold(0.0, (s, l) => s + l.importe);
}
