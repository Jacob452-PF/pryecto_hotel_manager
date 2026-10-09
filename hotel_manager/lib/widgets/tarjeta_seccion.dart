import 'package:flutter/material.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

/// Tarjeta con título e ícono que agrupa una sección de la pantalla.
class TarjetaSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget hijo;

  const TarjetaSeccion({
    super.key,
    required this.titulo,
    required this.icono,
    required this.hijo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(titulo, style: EstilosTexto.tituloTarjeta),
              ],
            ),
            const SizedBox(height: 12),
            hijo,
          ],
        ),
      ),
    );
  }
}