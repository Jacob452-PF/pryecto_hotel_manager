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

  // Acciones
  static const Color cancelar = Color(0xFFD32F2F);

  // Estados de las habitaciones
  static const Color disponible = Colors.green;
  static const Color ocupadaEstandar = Colors.red;
  static const Color ocupadaEspecial = Colors.purple;
  static const Color limpieza = Colors.orange;
  static const Color mantenimiento = Colors.blueGrey;
}