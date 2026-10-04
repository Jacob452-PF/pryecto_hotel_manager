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

  /// Precio por unidad (hora o noche) según la cantidad de camas.
  /// A más camas, mayor precio.
  final Map<int, double> precioPorCamas;

  const Tarifa(this.tipo, this.precioPorCamas);

  double precioPara(int camas) {
    assert(precioPorCamas.containsKey(camas),
        'No hay precio definido para $camas camas');
    return precioPorCamas[camas] ?? 0;
  }
}