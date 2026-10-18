import 'package:flutter/material.dart';

import '../modelos/notificacion_app.dart';
import '../servicios/servicio_notificaciones.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  @override
  void initState() {
    super.initState();
    ServicioNotificaciones.instancia.marcarTodasLeidas();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioNotificaciones.instancia,
      builder: (context, _) {
        final todas = ServicioNotificaciones.instancia.notificaciones;
        final urgentes = todas
            .where((n) => n.severidad == SeveridadNotificacion.urgente)
            .toList();
        final leves = todas
            .where((n) => n.severidad == SeveridadNotificacion.leve)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Notificaciones')),
          body: todas.isEmpty
              ? const _Vacio()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (urgentes.isNotEmpty) ...[
                      _TituloGrupo(
                        titulo: 'Urgentes',
                        cantidad: urgentes.length,
                        color: const Color(0xFFD32F2F),
                        icono: Icons.error,
                      ),
                      const SizedBox(height: 8),
                      for (final notificacion in urgentes)
                        _TarjetaNotificacion(notificacion: notificacion),
                    ],
                    if (leves.isNotEmpty) ...[
                      if (urgentes.isNotEmpty) const SizedBox(height: 18),
                      _TituloGrupo(
                        titulo: 'Leves',
                        cantidad: leves.length,
                        color: const Color(0xFFF57C00),
                        icono: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 8),
                      for (final notificacion in leves)
                        _TarjetaNotificacion(notificacion: notificacion),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final Color color;
  final IconData icono;

  const _TituloGrupo({
    required this.titulo,
    required this.cantidad,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icono, color: color),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(
            '$cantidad',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TarjetaNotificacion extends StatelessWidget {
  final NotificacionApp notificacion;
  const _TarjetaNotificacion({required this.notificacion});

  @override
  Widget build(BuildContext context) {
    final urgente = notificacion.severidad == SeveridadNotificacion.urgente;
    final color = urgente
        ? const Color(0xFFD32F2F)
        : const Color(0xFFF57C00);
    final fecha = notificacion.fecha;
    final momento =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} · '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.13),
          child: Icon(
            urgente ? Icons.priority_high : Icons.schedule,
            color: color,
          ),
        ),
        title: Text(notificacion.titulo),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notificacion.mensaje),
              const SizedBox(height: 5),
              Text(
                momento,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 52,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay notificaciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Aquí aparecerán los avisos de estadías e inventario.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
