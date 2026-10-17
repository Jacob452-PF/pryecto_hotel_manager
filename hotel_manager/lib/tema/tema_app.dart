import 'package:flutter/material.dart';

import 'paletas_tema.dart';

/// Tema global: la selección actual cambia fondos, tarjetas y controles.
class TemaApp {
  TemaApp._();

  static ThemeData crear(PaletaTema paleta) {
    final esquema = ColorScheme.fromSeed(
      seedColor: paleta.color,
      brightness: paleta.fondo.computeLuminance() < 0.2
          ? Brightness.dark
          : Brightness.light,
    ).copyWith(
      primary: paleta.color,
      onPrimary: Colors.white,
      secondary: paleta.acento,
      onSecondary: paleta.fondo.computeLuminance() < 0.2
          ? const Color(0xFF102126)
          : Colors.white,
      surface: paleta.superficie,
      onSurface: paleta.texto,
      surfaceContainerHighest: paleta.superficieSuave,
      onSurfaceVariant: paleta.textoSecundario,
    );
    final radio = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: paleta.fondo,
      canvasColor: paleta.fondo,
      dividerColor: paleta.textoSecundario.withValues(alpha: 0.18),
      appBarTheme: AppBarTheme(
        backgroundColor: paleta.fondo,
        foregroundColor: paleta.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: paleta.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: paleta.color.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: radio,
          side: BorderSide(color: paleta.color.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleta.superficie,
        border: OutlineInputBorder(borderRadius: radio),
        enabledBorder: OutlineInputBorder(
          borderRadius: radio,
          borderSide: BorderSide(color: paleta.textoSecundario.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radio,
          borderSide: BorderSide(color: paleta.color, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: paleta.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paleta.color,
          side: BorderSide(color: paleta.color.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: paleta.color),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paleta.superficieSuave,
        side: BorderSide.none,
        labelStyle: TextStyle(color: paleta.texto),
      ),
      iconTheme: IconThemeData(color: paleta.color),
    );
  }
}
