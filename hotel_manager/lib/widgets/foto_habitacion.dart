import 'dart:io';
import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

/// Foto de la habitación. Si todavía no hay foto, muestra un marcador.
class FotoHabitacion extends StatelessWidget {
  final String? rutaFoto;
  const FotoHabitacion({super.key, this.rutaFoto});

  Widget _marcador() => Container(
        color: ColoresApp.bordeSuave.withValues(alpha: 0.3),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: ColoresApp.textoSecundario),
              SizedBox(height: 8),
              Text('Sin foto', style: EstilosTexto.textoVacio),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: rutaFoto == null
            ? _marcador()
            : Image.file(
                File(rutaFoto!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _marcador(),
              ),
      ),
    );
  }
}