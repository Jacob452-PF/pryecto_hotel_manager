import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

/// Tarjeta tocable del perfil: ícono, título y descripción corta.
class TarjetaOpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;
  final Color? colorIcono;

  const TarjetaOpcionPerfil({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alTocar,
    this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icono, size: 32, color: colorIcono),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: EstilosTexto.tituloOpcion),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: EstilosTexto.detalleOpcion),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ColoresApp.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
