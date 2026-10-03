import 'package:flutter/material.dart';

enum TipoTarifa {
  porHora('Por hora', 'hora', 'horas', Icons.schedule),
  porNoche('Por noche', 'noche', 'noches', Icons.nights_stay);

  const TipoTarifa(this.etiqueta, this.unidadSingular, this.unidadPlural, this.icono);
  final String etiqueta;
  final String unidadSingular;
  final String unidadPlural;
  final IconData icono;

  String unidad(int cantidad) => cantidad == 1 ? unidadSingular : unidadPlural;
}

class Tarifa {
  final TipoTarifa tipo;
  final double precioUnitario;
  const Tarifa(this.tipo, this.precioUnitario);
} 