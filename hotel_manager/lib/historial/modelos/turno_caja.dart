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
  alimentos('Productos', Icons.restaurant),
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

/// Lo que el hotel gastó en comprar productos o reponer stock (viene del inventario).
class GastoInventarioTurno {
  final String producto;

  /// Por ejemplo "Reposición · +24 uds".
  final String detalle;
  final double monto;

  const GastoInventarioTurno(this.producto, this.detalle, this.monto);
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

  /// Compras de inventario hechas durante el turno.
  final List<GastoInventarioTurno> gastosInventario;

  const TurnoCaja({
    required this.usuario,
    required this.ventas,
    required this.gastos,
    required this.habitacionesOcupadas,
    required this.habitacionesTotal,
    this.clientes = const [],
    this.gastosInventario = const [],
  });

  double get totalVentas => ventas.fold(0.0, (s, v) => s + v.monto);
  int get cantidadVentas => ventas.fold(0, (s, v) => s + v.cantidad);

  /// Gastos registrados a mano (cocina, limpieza, mantenimiento...).
  double get totalGastos => gastos.fold(0.0, (s, g) => s + g.monto);

  /// Lo que se gastó en comprar productos o reponer stock.
  double get totalGastosInventario =>
      gastosInventario.fold(0.0, (s, g) => s + g.monto);

  /// Todos los gastos del turno: los de arriba + inventario.
  double get gastosTotales => totalGastos + totalGastosInventario;

  /// Cantidad de registros de gasto (para la tarjeta "Gastos del turno").
  int get cantidadGastos => gastos.length + gastosInventario.length;

  /// Lo que debe haber en caja: ventas - todos los gastos.
  double get totalEnCaja => totalVentas - gastosTotales;
}
