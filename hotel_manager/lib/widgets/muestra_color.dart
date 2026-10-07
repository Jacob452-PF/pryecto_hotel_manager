import 'package:flutter/material.dart';

import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';
import '../tema/paletas_tema.dart';

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
    return Tooltip(
      message: paleta.nombre,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        onTap: alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 112,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
            border: Border.all(
              color: seleccionada ? paleta.color : Colors.black12,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: paleta.color,
                  shape: BoxShape.circle,
                ),
                child: seleccionada
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                paleta.nombre,
                style: EstilosTexto.detalleOpcion,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
