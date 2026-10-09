import 'package:flutter/material.dart';

import '../servicios/servicio_tema.dart';
import '../tema/estilos_texto.dart';
import '../tema/paletas_tema.dart';
import '../widgets/muestra_color.dart';
import '../widgets/tarjeta_seccion.dart';

/// El usuario elige el color principal de la app para su estación de trabajo.
/// El cambio se aplica al instante y se recuerda al cerrar la app.
class PantallaTema extends StatelessWidget {
  const PantallaTema({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioTema.instancia,
      builder: (context, _) {
        final actual = ServicioTema.instancia.paleta;

        return Scaffold(
          appBar: AppBar(title: const Text('Tema de la app')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Elige los colores con los que te sientas más cómodo en tu estación de trabajo.',
                  style: EstilosTexto.textoVacio,
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Color principal',
                  icono: Icons.palette,
                  hijo: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final paleta in PaletasTema.todas)
                        MuestraColor(
                          paleta: paleta,
                          seleccionada: paleta == actual,
                          alTocar: () => ServicioTema.instancia.elegir(paleta),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Vista previa',
                  icono: Icons.visibility,
                  hijo: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Botón principal'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Botón secundario'),
                      ),
                      const Chip(label: Text('Etiqueta')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
