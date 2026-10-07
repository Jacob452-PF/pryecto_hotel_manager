import 'package:flutter/material.dart';
import 'colores_app.dart';

/// Tema general de la app: lo que aquí se define aplica a todas las pantallas.
class TemaApp {
  TemaApp._();

  /// Crea el tema a partir del color principal elegido por el usuario.
  static ThemeData crear(Color colorPrimario) {
    final esquema = ColorScheme.fromSeed(seedColor: colorPrimario).copyWith(
      primary: colorPrimario,
      onPrimary: ColoresApp.sobrePrimario,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      // Barra superior de las pantallas secundarias
      appBarTheme: AppBarTheme(
        backgroundColor: colorPrimario,
        foregroundColor: ColoresApp.sobrePrimario,
      ),
      // Todos los campos de texto con borde
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      // Todos los botones con el mismo alto
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}