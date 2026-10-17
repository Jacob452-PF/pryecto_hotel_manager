import 'package:flutter/material.dart';

import 'consumo_cliente.dart';

enum TipoVenta {
  habitaciones('Habitaciones', Icons.bed_outlined),
  servicios('Servicios', Icons.room_service_outlined),
  productos('Productos del hotel', Icons.shopping_bag_outlined);

  final String etiqueta;
  final IconData icono;
  const TipoVenta(this.etiqueta, this.icono);
}

enum CategoriaGasto {
  alimentos('Alimentos', Icons.restaurant),
  aseo('Aseo', Icons.cleaning_services),
  mantenimiento('Mantenimiento', Icons.build),
  otros('Otros', Icons.more_horiz);

  final String etiqueta;
  final IconData icono;
  const CategoriaGasto(this.etiqueta, this.icono);
}

class VentaTurno {
  final TipoVenta tipo;
  final int cantidad;
  final double monto;

  const VentaTurno(this.tipo, this.cantidad, this.monto);
}

class GastoTurno {
  final CategoriaGasto categoria;
  final String descripcion;
  final double monto;

  const GastoTurno(this.categoria, this.descripcion, this.monto);
}

/// Resumen del turno que se va a cerrar.
class TurnoCaja {
  final String usuario;
  final List<VentaTurno> ventas;
  final List<GastoTurno> gastos;
  final int habitacionesOcupadas;
  final int habitacionesTotal;

  /// Clientes registrados en el turno, con todo lo que consumieron.
  final List<ConsumoCliente> clientes;

  const TurnoCaja({
    required this.usuario,
    required this.ventas,
    required this.gastos,
    required this.habitacionesOcupadas,
    required this.habitacionesTotal,
    this.clientes = const [],
  });

  double get totalVentas => ventas.fold(0.0, (s, v) => s + v.monto);
  int get cantidadVentas => ventas.fold(0, (s, v) => s + v.cantidad);
  double get totalGastos => gastos.fold(0.0, (s, g) => s + g.monto);

  /// Lo que debe haber en caja: ventas - gastos.
  double get totalEnCaja => totalVentas - totalGastos;
}
