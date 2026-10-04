import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';

/// Fila con ícono, etiqueta pequeña y valor. Se usa en el detalle de habitación.
class FilaInformacion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;

  const FilaInformacion({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, color: colorValor ?? ColoresApp.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: EstilosTexto.etiquetaInformacion),
                Text(
                  valor,
                  style: EstilosTexto.valorInformacion.copyWith(color: colorValor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}