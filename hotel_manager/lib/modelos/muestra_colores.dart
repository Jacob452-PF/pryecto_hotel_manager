import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../tema/paletas_tema.dart';

/// Círculo de color que el usuario toca para elegir su paleta.
class MuestraColor extends StatelessWidget {
  final PaletaTema paleta;
  final bool seleccionada;
  final VoidCallback alTocar;

  const MuestraColor({
    super.key,
    required this.paleta,
    required this.seleccionada,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: paleta.color,
                shape: BoxShape.circle,
                border: seleccionada
                    ? Border.all(color: ColoresApp.textoSecundario, width: 3)
                    : null,
              ),
              child: seleccionada
                  ? const Icon(Icons.check, color: ColoresApp.sobrePrimario)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(paleta.nombre, style: EstilosTexto.etiquetaInformacion),
          ],
        ),
      ),
    );
  }
}