import 'package:flutter/material.dart';
import 'colores_app.dart';

/// Todos los estilos de texto de la app en un solo lugar.
/// Si un estilo necesita otro color, se usa .copyWith(color: ...) donde se aplique.
class EstilosTexto {
  EstilosTexto._();

  // Encabezado de la pantalla de inicio
  static const TextStyle tituloEncabezado = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: ColoresApp.sobrePrimario,
  );
  static const TextStyle subtituloEncabezado = TextStyle(
    fontSize: 14,
    color: ColoresApp.sobrePrimarioSuave,
  );
  static const TextStyle horaEncabezado = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ColoresApp.sobrePrimario,
  );
  static const TextStyle fechaEncabezado = TextStyle(
    fontSize: 12,
    color: ColoresApp.sobrePrimarioSuave,
  );

  // Títulos de sección
  static const TextStyle tituloSeccion =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static const TextStyle subtituloSeccion =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  // Login
  static const TextStyle tituloLogin =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w600);

  // Cuadros de resumen
  static const TextStyle numeroResumen =
      TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static const TextStyle etiquetaResumen = TextStyle(fontSize: 11);

  // Tarjeta de habitación
  static const TextStyle numeroHabitacion =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle detalleHabitacion = TextStyle(fontSize: 11);
  static const TextStyle estadoHabitacion =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  // Nuevo huésped: tarjetas y recuadros
  static const TextStyle tituloTarjeta =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle textoVacio =
      TextStyle(fontSize: 14, color: ColoresApp.textoSecundario);
  static const TextStyle etiquetaOpcion =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle detalleOpcion =
      TextStyle(fontSize: 12, color: ColoresApp.textoSecundario);
  static const TextStyle numeroContador =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  // Nuevo huésped: factura
  static const TextStyle textoFactura = TextStyle(fontSize: 14);
  static const TextStyle detalleFactura =
      TextStyle(fontSize: 13, color: ColoresApp.textoSecundario);
  static const TextStyle totalFactura =
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  // Detalle de habitación
  static const TextStyle etiquetaInformacion =
      TextStyle(fontSize: 13, color: ColoresApp.textoSecundario);
  static const TextStyle valorInformacion =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  // Perfil de caja
  static const TextStyle tituloOpcion =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle etiquetaPerfil =
      TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
  static const TextStyle valorPerfil = TextStyle(fontSize: 15);

  static TextStyle? get parrafoSeccion => null;
}