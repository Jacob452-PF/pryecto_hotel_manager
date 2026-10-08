import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

class PantallaAcercaApp extends StatelessWidget {
  const PantallaAcercaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      appBar: AppBar(title: const Text('Acerca de la app')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _FilaVersion(),
            SizedBox(height: 18),
            _BloqueTexto(
              titulo: 'Misión',
              texto: 'Proporcionar una plataforma digital eficiente e intuitiva que optimice la administración integral del hotel y eleve la experiencia de los huéspedes. Nos enfocamos en centralizar la gestión de reservas, el control de habitaciones y la atención al cliente en una sola herramienta, agilizando los procesos operativos para garantizar un servicio de hospitalidad ágil, moderno y de excelencia bajo el estándar de la familia López.',
            ),
            SizedBox(height: 18),
            _BloqueTexto(
              titulo: 'Visión',
              texto: 'Posicionarnos como la solución tecnológica referente en el sector hotelero local y regional, reconocida por transformar la administración tradicional en un ecosistema digital inteligente. Aspiramos a establecer un modelo de innovación donde la automatización, el diseño accesible y la eficiencia operativa potencien el crecimiento continuo del negocio y la fidelización de cada visitante.',
            ),
            SizedBox(height: 18),
            Text('Soporte técnico', style: EstilosTexto.subtituloSeccion),
            SizedBox(height: 8),
            _TarjetaSoporte(),
          ],
        ),
      ),
    );
  }
}

class _FilaVersion extends StatelessWidget {
  const _FilaVersion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Versión', style: EstilosTexto.etiquetaOpcion)),
          Text('1.0.0.1', style: EstilosTexto.valorInformacion),
        ],
      ),
    );
  }
}

class _BloqueTexto extends StatelessWidget {
  final String titulo;
  final String texto;

  const _BloqueTexto({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: EstilosTexto.subtituloSeccion),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.superficieSuave,
            borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: EstilosTexto.parrafoSeccion,
          ),
        ),
      ],
    );
  }
}

class _TarjetaSoporte extends StatelessWidget {
  const _TarjetaSoporte();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficieSuave,
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tecnología López', style: EstilosTexto.subtituloSeccion),
          SizedBox(height: 10),
          Text('Oscar Moisés', style: EstilosTexto.valorInformacion),
          Text(
            'Contacto: +503 7733 0170',
            style: EstilosTexto.valorInformacion,
          ),
        ],
      ),
    );
  }
}
