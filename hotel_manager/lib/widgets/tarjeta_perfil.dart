import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';

/// Tarjeta superior del perfil: foto, nombre, cargo, edad y hora de inicio de sesión.
class TarjetaPerfil extends StatelessWidget {
  final Usuario usuario;
  final DateTime? inicioSesion;

  const TarjetaPerfil({super.key, required this.usuario, this.inicioSesion});

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$etiqueta: ', style: EstilosTexto.etiquetaPerfil),
            TextSpan(text: valor, style: EstilosTexto.valorPerfil),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorPrimario, width: 3),
                  ),
                  child: Icon(Icons.person, size: 48, color: colorPrimario),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.fondoSuave,
                      borderRadius: BorderRadius.circular(
                        Dimensiones.radioTarjeta,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dato('Nombre', usuario.nombre),
                        _dato('Cargo', usuario.cargo),
                        _dato('Edad', usuario.edad?.toString() ?? '—'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (inicioSesion != null) ...[
              const SizedBox(height: 12),
              Text(
                'Sesión iniciada: ${formatearFechaHora(inicioSesion!)}',
                style: EstilosTexto.etiquetaInformacion,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
