import 'package:flutter/material.dart';

class PantallaTutorial extends StatelessWidget {
  const PantallaTutorial({super.key});

  static const _secciones = <({IconData icono, String titulo, String texto})>[
    (
      icono: Icons.login,
      titulo: 'Iniciar sesión',
      texto: 'Escribe tu correo y contraseña. La app recuerda el correo para la próxima vez. Tu sesión se conserva hasta que cierres sesión desde Perfil.',
    ),
    (
      icono: Icons.dashboard_outlined,
      titulo: 'Muévete por la app',
      texto: 'La barra inferior permite abrir Inicio, Agenda, Tienda, Inventario, Historial y Perfil. Las opciones visibles dependen de tu cargo.',
    ),
    (
      icono: Icons.calendar_month_outlined,
      titulo: 'Reservas y habitaciones',
      texto: 'En Agenda consulta las reservas por fecha, crea nuevas, registra abonos y realiza el check-in. En Inicio consulta el estado de las habitaciones y las tareas.',
    ),
    (
      icono: Icons.point_of_sale_outlined,
      titulo: 'Abrir y cerrar caja',
      texto: 'Recepción abre su caja al entrar si no tiene un turno abierto. Cuenta billetes y monedas para registrar el monto inicial. Al terminar el turno, cierra la caja desde Perfil o Historial.',
    ),
    (
      icono: Icons.storefront_outlined,
      titulo: 'Ventas e inventario',
      texto: 'En Tienda registra ventas y consumos. En Inventario consulta existencias, productos y movimientos; algunas opciones solo están disponibles para administración.',
    ),
    (
      icono: Icons.notifications_active_outlined,
      titulo: 'Avisos',
      texto: 'El icono de campana muestra los avisos de estadías, inventario y reservas. Los avisos urgentes y leves aparecen en la bandeja; toca “Ver” en el aviso emergente para abrir su detalle.',
    ),
    (
      icono: Icons.wifi_off_outlined,
      titulo: 'Si se pierde la conexión',
      texto: 'Aparecerá un aviso grande mientras la app intenta reconectarse. La sesión se conserva y el aviso desaparece cuando el servidor vuelve a responder.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cómo usar Hotel Manager')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Guía rápida',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final seccion in _secciones)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: CircleAvatar(child: Icon(seccion.icono)),
              title: Text(
                seccion.titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(seccion.texto),
              ),
              isThreeLine: true,
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver al inicio de sesión'),
        ),
      ],
    ),
  );
}
