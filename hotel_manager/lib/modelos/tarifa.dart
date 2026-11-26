import 'package:flutter/material.dart';

enum TipoTarifa {
  porHora('Por hora', 'hora', 'horas', Icons.schedule),
  porNoche('Por noche', 'noche', 'noches', Icons.nights_stay);

  const TipoTarifa(
    this.etiqueta,
    this.unidadSingular,
    this.unidadPlural,
    this.icono,
  );
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
    assert(
      precioPorCamas.containsKey(camas),
      'No hay precio definido para $camas camas',
    );
    return precioPorCamas[camas] ?? 0;
  }
}

/// Tarifa activa recibida de la API; su precio y duración son autoridad del
/// backend para reservas compartidas.
class TarifaRemota {
  final int id;
  final String nombre;
  final int horas;
  final double precio;
  final String? tipoHabitacion;
  final int? camas;

  const TarifaRemota({
    required this.id,
    required this.nombre,
    required this.horas,
    required this.precio,
    this.tipoHabitacion,
    this.camas,
  });

  factory TarifaRemota.fromJson(Map<String, dynamic> json) => TarifaRemota(
    id: int.parse(json['id'].toString()),
    nombre: json['name']?.toString() ?? 'Tarifa',
    horas: int.parse(json['hours'].toString()),
    precio: double.parse(json['price'].toString()),
    tipoHabitacion: json['room_type']?.toString(),
    camas: int.tryParse(json['beds']?.toString() ?? ''),
  );

  String get etiquetaDuracion => '$nombre · $horas h · ${camas ?? '?'} camas';
}
