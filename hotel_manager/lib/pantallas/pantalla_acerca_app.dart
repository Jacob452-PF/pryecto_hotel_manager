import 'package:flutter/material.dart';

import '../tema/dimensiones.dart';

class PantallaAcercaApp extends StatelessWidget {
  const PantallaAcercaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de la app')),
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey<String>('pantalla-acerca-app'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _EncabezadoAcerca(color: tema.colorScheme.primary),
            const SizedBox(height: 22),
            const _SeccionAcerca(
              icono: Icons.apartment_rounded,
              titulo: '¿Qué es Hotel Manager?',
              texto: 'Una herramienta para coordinar las tareas diarias del hotel desde un solo lugar. Consulta habitaciones, administra reservas y estadías, registra ventas y gastos, controla inventario y organiza tareas de limpieza y mantenimiento. Cada cuenta muestra las opciones correspondientes a su cargo.',
            ),
            const SizedBox(height: 12),
            const _SeccionAcerca(
              icono: Icons.grid_view_rounded,
              titulo: 'Todo en un mismo lugar',
              texto: 'Inicio muestra habitaciones y estados; Agenda reúne reservas, fechas, abonos y entradas; Tienda registra ventas y consumos; Inventario muestra existencias y movimientos; Historial permite revisar ventas, gastos y cierres de caja. En Perfil encuentras ajustes, conexión, tema y este tutorial.',
            ),
            const SizedBox(height: 12),
            const _EstadosHabitacion(),
            const SizedBox(height: 22),
            Text('Nuestro propósito', style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const _SeccionAcerca(
              icono: Icons.flag_rounded,
              titulo: 'Misión',
              texto: 'Proporcionar una plataforma digital eficiente e intuitiva que optimice la administración integral del hotel y eleve la experiencia de los huéspedes. Centralizamos reservas, habitaciones y atención para agilizar la operación diaria.',
            ),
            const SizedBox(height: 12),
            const _SeccionAcerca(
              icono: Icons.visibility_rounded,
              titulo: 'Visión',
              texto: 'Ser una solución tecnológica referente para la administración hotelera local y regional, impulsando procesos más claros, accesibles y eficientes mediante herramientas digitales.',
            ),
            const SizedBox(height: 22),
            Text('Personas detrás de la app', style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const _TarjetaPersonas(),
            const SizedBox(height: 12),
            const _TarjetaSoporte(),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Hecha para facilitar cada turno',
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoAcerca extends StatelessWidget {
  final Color color;
  const _EncabezadoAcerca({required this.color});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, .24)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hotel Manager', style: tema.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Gestión clara para cada turno', style: tema.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .88))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
                  child: const Text('VERSIÓN 1.0.0.1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionAcerca extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  const _SeccionAcerca({required this.icono, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final primario = tema.colorScheme.primary;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        side: BorderSide(color: tema.colorScheme.outlineVariant.withValues(alpha: .5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: primario.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
              child: Icon(icono, color: primario),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  Text(texto, style: tema.textTheme.bodyMedium?.copyWith(height: 1.45, color: tema.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadosHabitacion extends StatelessWidget {
  const _EstadosHabitacion();

  static const _estados = [
    ('Disponible', 'Lista para asignar', Color(0xFF43A047)),
    ('Reservada', 'Tiene una reserva pendiente', Color(0xFF7E57C2)),
    ('Ocupada', 'Tiene una estadía activa', Color(0xFFE53935)),
    ('En limpieza', 'No se asigna hasta terminar la tarea', Color(0xFFEF8C22)),
    ('Mantenimiento', 'Requiere atención técnica', Color(0xFF607D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta), side: BorderSide(color: tema.colorScheme.outlineVariant.withValues(alpha: .5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.circle_rounded, color: tema.colorScheme.primary, size: 20), const SizedBox(width: 10), Text('Estados de habitación', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 12),
            for (final estado in _estados)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(width: 11, height: 11, decoration: BoxDecoration(color: estado.$3, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    SizedBox(width: 104, child: Text(estado.$1, style: tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                    Expanded(child: Text(estado.$2, style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPersonas extends StatelessWidget {
  const _TarjetaPersonas();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final persona in [('JP', 'Jacob Perez'), ('GC', 'Gisela Cortes'), ('SL', 'Steven Lopez')])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: tema.colorScheme.primaryContainer, child: Text(persona.$1, style: TextStyle(color: tema.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                title: Text(persona.$2, style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSoporte extends StatelessWidget {
  const _TarjetaSoporte();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.secondaryContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.support_agent_rounded, size: 34, color: tema.colorScheme.onSecondaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soporte técnico', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: tema.colorScheme.onSecondaryContainer)),
                  const SizedBox(height: 5),
                  Text('Jacob Perez · 7978-5112', style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSecondaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
