import 'package:flutter/material.dart';

/// Todos los colores de la app en un solo lugar.
class ColoresApp {
  ColoresApp._();

  // Marca
  static const Color primario = Color(0xFF1E5AA8);
  static const Color sobrePrimario = Colors.white;
  static const Color sobrePrimarioSuave = Color(0xD9FFFFFF); // blanco al 85 %
  static const Color fondoLogin = primario;

  // Textos y bordes
  static const Color textoSecundario = Color(0xFF616161);
  static const Color bordeSuave = Color(0xFFBDBDBD);
  static const Color fondoSuave = Color(0xFFF5F2FB);
  static const Color superficieSuave = Color(0xFFE0E0E0);

  // Acciones
  static const Color cancelar = Color(0xFFD32F2F);
  static const Color advertencia = Color(0xFFE7A52F);

  // Estados de las habitaciones
  static const Color disponible = Colors.green;
  static const Color ocupada = Colors.red;
  static const Color limpieza = Colors.orange;
  static const Color mantenimiento = Colors.blueGrey;
}
