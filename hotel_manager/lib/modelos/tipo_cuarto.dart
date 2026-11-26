import 'package:flutter/material.dart';

/// Clasificación de habitaciones que usa la app.
enum TipoCuarto {
  comun('Común', Icons.single_bed),
  especial('Especial', Icons.king_bed);

  const TipoCuarto(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
  String get valorApi => this == TipoCuarto.comun ? 'estandar' : 'especial';

  /// Lee los valores actuales y los nombres históricos guardados por la app.
  /// Las habitaciones matrimoniales y familiares ahora pertenecen a Especial.
  static TipoCuarto desdeNombre(String nombre) => switch (
    nombre.trim().toLowerCase()
  ) {
    'comun' || 'común' || 'common' || 'estandar' || 'estándar' ||
    'standard' || 'individual' || 'single' || 'twin' => TipoCuarto.comun,
    'especial' || 'special' || 'matrimonial' || 'double' || 'doubled' ||
    'queen' || 'king' || 'familiar' || 'family' => TipoCuarto.especial,
    _ => throw FormatException('Tipo de habitación no reconocido: $nombre'),
  };
}
