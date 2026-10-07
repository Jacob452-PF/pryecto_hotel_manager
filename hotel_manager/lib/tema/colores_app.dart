import 'package:flutter/material.dart';

/// Todos los colores fijos de la app en un solo lugar.
/// El color principal que ve el usuario sale del tema (ver paletas_tema.dart);
/// `primario` es solo el color por defecto.
class ColoresApp {
  ColoresApp._();

  // Marca
  static const Color primario = Color(0xFF1E5AA8);
  static const Color sobrePrimario = Colors.white;
  static const Color sobrePrimarioSuave = Color(0xD9FFFFFF); // blanco al 85 %

  // Textos, fondos y bordes
  static const Color textoSecundario = Color(0xFF616161);
  static const Color bordeSuave = Color(0xFFBDBDBD);
  static const Color fondoLogin = primario;
  static const Color fondoSuave = Color(0xFFE8E8E8);
  static const Color superficieSuave = Color(0xFFFFFFFF);

  // Acciones
  static const Color cancelar = Color(0xFFD32F2F);
  static const Color advertencia = Color(0xFFE7A52F);

  // Estados de las habitaciones
  static const Color disponible = Colors.green;
  static const Color ocupada = Colors.red;
  static const Color limpieza = Colors.orange;
  static const Color mantenimiento = Colors.blueGrey;
}
