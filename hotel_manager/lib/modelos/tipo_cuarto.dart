import 'package:flutter/material.dart';

/// Tipo de cuarto según su distribución (matrimonial, individual, familiar).
enum TipoCuarto {
  matrimonial('Matrimonial', Icons.king_bed),
  individual('Individual', Icons.single_bed),
  familiar('Familiar', Icons.family_restroom);

  const TipoCuarto(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}
