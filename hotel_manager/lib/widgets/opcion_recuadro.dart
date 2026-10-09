import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

/// Recuadro seleccionable (tarifa, tipo de cuarto, camas, habitaciones).
class OpcionRecuadro extends StatelessWidget {
  final String etiqueta;
  final String? detalle;
  final IconData? icono;
  final bool seleccionada;
  final VoidCallback alTocar;

  const OpcionRecuadro({
    super.key,
    required this.etiqueta,
    required this.seleccionada,
    required this.alTocar,
    this.detalle,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final radio = BorderRadius.circular(Dimensiones.radioTarjeta);
    final colorIcono = seleccionada ? colorPrimario : ColoresApp.textoSecundario;

    return Material(
      color: seleccionada ? colorPrimario.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: radio,
      child: InkWell(
        borderRadius: radio,
        onTap: alTocar,
        child: Container(
          constraints: const BoxConstraints(minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: radio,
            border: Border.all(
              color: seleccionada ? colorPrimario : ColoresApp.bordeSuave,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) Icon(icono, color: colorIcono),
              if (icono != null) const SizedBox(height: 4),
              Text(
                etiqueta,
                style: EstilosTexto.etiquetaOpcion.copyWith(
                  color: seleccionada ? colorPrimario : null,
                ),
              ),
              if (detalle != null) Text(detalle!, style: EstilosTexto.detalleOpcion),
            ],
          ),
        ),
      ),
    );
  }
}