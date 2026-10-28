import 'package:flutter/material.dart';

import '../tema/dimensiones.dart';

class PantallaAcercaApp extends StatelessWidget {
  const PantallaAcercaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Acerca de la app')),
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey<String>('pantalla-acerca-app'),
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
            Text('Programadores'),
            SizedBox(height: 8),
            _TarjetaProgramadores(),
            SizedBox(height: 18),
            Text('Soporte técnico'),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Versión')),
          Text('1.0.0.1'),
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
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tema.colorScheme.surface,
            borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurface,
            ),
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
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información de contacto', style: tema.textTheme.titleSmall),
          const SizedBox(height: 10),
          const Text('Jacob Perez'),
          const Text('7978-5112'),
        ],
      ),
    );
  }
}

class _TarjetaProgramadores extends StatelessWidget {
  const _TarjetaProgramadores();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grupo de Programadores', style: tema.textTheme.titleSmall),
          const SizedBox(height: 10),
          const Text('Jacob Perez'),
          const Text('Gisela Cortes'),
          const Text('Steven Lopez'),
        ],
      ),
    );
  }
}
