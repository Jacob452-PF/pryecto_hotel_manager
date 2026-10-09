import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';

/// Provisional: esta sección sigue en planificación.
class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de la app')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 48, color: ColoresApp.textoSecundario),
              SizedBox(height: 12),
              Text('Sección en planificación', style: EstilosTexto.tituloOpcion),
              SizedBox(height: 8),
              Text(
                'Aquí irán las preferencias, las notificaciones y la sincronización.',
                style: EstilosTexto.textoVacio,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}