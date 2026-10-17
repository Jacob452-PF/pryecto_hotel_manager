import 'package:flutter/material.dart';

/// Paleta completa que controla superficies y controles de toda la app.
class PaletaTema {
  final String nombre;
  final String detalle;
  final Color color;
  final Color acento;
  final Color fondo;
  final Color superficie;
  final Color superficieSuave;
  final Color texto;
  final Color textoSecundario;
  final IconData icono;

  const PaletaTema({
    required this.nombre,
    required this.detalle,
    required this.color,
    required this.acento,
    required this.fondo,
    required this.superficie,
    required this.superficieSuave,
    required this.texto,
    required this.textoSecundario,
    required this.icono,
  });
}

/// Temas inspirados en los acabados cristalinos y los tonos de los logos.
class PaletasTema {
  PaletasTema._();

  static const PaletaTema aurora = PaletaTema(
    nombre: 'Aurora Hotel',
    detalle: 'Cristal, turquesa y violeta sobre una base luminosa.',
    color: Color(0xFF087E83),
    acento: Color(0xFF8B63D9),
    fondo: Color(0xFFF0F5FA),
    superficie: Color(0xFFFFFFFF),
    superficieSuave: Color(0xFFE5F2F3),
    texto: Color(0xFF172A3A),
    textoSecundario: Color(0xFF617481),
    icono: Icons.auto_awesome,
  );

  static const PaletaTema nocheCristal = PaletaTema(
    nombre: 'Noche cristal',
    detalle: 'Carbón profundo con reflejos de luz cian.',
    color: Color(0xFF087F89),
    acento: Color(0xFF7DE3E3),
    fondo: Color(0xFF10191F),
    superficie: Color(0xFF1B292F),
    superficieSuave: Color(0xFF26383E),
    texto: Color(0xFFEAF5F5),
    textoSecundario: Color(0xFFB3C6C8),
    icono: Icons.dark_mode_outlined,
  );

  static const PaletaTema esmeralda = PaletaTema(
    nombre: 'Esmeralda premium',
    detalle: 'Verde profundo y azul nocturno con acabado elegante.',
    color: Color(0xFF087F72),
    acento: Color(0xFF41C7C0),
    fondo: Color(0xFFEEF5F4),
    superficie: Color(0xFFFFFFFF),
    superficieSuave: Color(0xFFDDF0EC),
    texto: Color(0xFF18312F),
    textoSecundario: Color(0xFF617C78),
    icono: Icons.diamond_outlined,
  );

  static const PaletaTema turquesa = PaletaTema(
    nombre: 'Turquesa luminoso',
    detalle: 'Un ambiente fresco inspirado en el logo turquesa.',
    color: Color(0xFF0099A6),
    acento: Color(0xFF40D5D0),
    fondo: Color(0xFFECF8F8),
    superficie: Color(0xFFFFFFFF),
    superficieSuave: Color(0xFFD6F3F1),
    texto: Color(0xFF153438),
    textoSecundario: Color(0xFF5B7D80),
    icono: Icons.water_drop_outlined,
  );

  static const List<PaletaTema> todas = [
    aurora,
    nocheCristal,
    esmeralda,
    turquesa,
  ];

  static const PaletaTema predeterminada = aurora;
}
