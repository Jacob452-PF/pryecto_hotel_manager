import 'package:flutter/material.dart';
import 'colores_app.dart';

/// Tema general de la app: lo que aquí se define aplica a todas las pantallas.
class TemaApp {
  TemaApp._();

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: ColoresApp.primario,
        // Barra superior de las pantallas secundarias
        appBarTheme: const AppBarTheme(
          backgroundColor: ColoresApp.primario,
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