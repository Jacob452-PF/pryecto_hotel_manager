import 'package:flutter/material.dart';

import '../modelos/solicitud_limpieza.dart';
import '../modelos/solicitud_mantenimiento.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_auth.dart';
import '../servicios/servicio_sesion.dart';
import '../servicios/servicio_tareas.dart';

class PantallaTareas extends StatelessWidget {
  const PantallaTareas({super.key});
  Future<String?> _elegirEmpleado(BuildContext context, RolUsuario rol) async {
    final lista = (await ServicioAuth.instancia.usuarios())
        .where((u) => u.activo && u.rol == rol)
        .toList();
    if (!context.mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          rol == RolUsuario.limpieza
              ? 'Asignar a limpieza'
              : 'Asignar a mantenimiento',
        ),
        children: lista.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay usuarios activos para asignar.'),
                ),
              ]
            : [
                for (final u in lista)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, u.id),
                    child: Text('${u.nombre} · ${u.username}'),
                  ),
              ],
      ),
    );
  }

  Future<void> _accion(
    BuildContext context,
    Future<void> Function() accion,
  ) async {
    try {
      await accion();
    } on Object catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ServicioSesion.instancia.usuario;
    final admin = usuario?.rol == RolUsuario.admin;
    final limpieza = usuario?.rol == RolUsuario.limpieza;
    final mantenimiento = usuario?.rol == RolUsuario.mantenimiento;
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: ListenableBuilder(
        listenable: ServicioTareas.instancia,
        builder: (context, _) {
          final s = ServicioTareas.instancia;
          final limpiezas = s.solicitudesLimpieza
              .where(
                (t) =>
                    t.estado != EstadoSolicitudLimpieza.lista &&
                    (admin ||
                        limpieza &&
                            (t.estado == EstadoSolicitudLimpieza.pendiente ||
                                t.asignadoA == usuario?.id)),
              )
              .toList();
          final mantenimientos = s.solicitudesMantenimiento
              .where(
                (t) =>
                    t.estado != EstadoSolicitudMantenimiento.resuelta &&
                    (admin ||
                        mantenimiento &&
                            (t.estado ==
                                    EstadoSolicitudMantenimiento.pendiente ||
                                t.asignadoA == usuario?.id)),
              )
              .toList();
          if (limpiezas.isEmpty && mantenimientos.isEmpty)
            return const Center(child: Text('No hay tareas pendientes.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (limpiezas.isNotEmpty) ...[
                Text('Limpieza', style: Theme.of(context).textTheme.titleLarge),
                for (final t in limpiezas)
                  _tarjetaLimpieza(context, t, s, admin, limpieza, usuario?.id),
              ],
              if (mantenimientos.isNotEmpty) ...[
                Text(
                  'Mantenimiento',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final t in mantenimientos)
                  _tarjetaMantenimiento(
                    context,
                    t,
                    s,
                    admin,
                    mantenimiento,
                    usuario?.id,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tarjetaLimpieza(
    BuildContext context,
    SolicitudLimpieza t,
    ServicioTareas s,
    bool admin,
    bool worker,
    String? userId,
  ) {
    final actions = <Widget>[];
    if (admin && t.estado == EstadoSolicitudLimpieza.pendiente)
      actions.add(
        TextButton(
          onPressed: () async {
            final id = await _elegirEmpleado(context, RolUsuario.limpieza);
            if (id != null && context.mounted)
              _accion(context, () => s.asignarLimpieza(t.id, id));
          },
          child: const Text('Asignar'),
        ),
      );
    if (worker && t.estado == EstadoSolicitudLimpieza.pendiente)
      actions.add(
        TextButton(
          onPressed: () => _accion(context, () => s.aceptarLimpieza(t.id)),
          child: const Text('Aceptar'),
        ),
      );
    if (worker &&
        t.asignadoA == userId &&
        (t.estado == EstadoSolicitudLimpieza.asignada ||
            t.estado == EstadoSolicitudLimpieza.aceptada))
      actions.add(
        TextButton(
          onPressed: () => _accion(context, () => s.iniciarLimpieza(t.id)),
          child: const Text('Iniciar'),
        ),
      );
    if (worker &&
        t.asignadoA == userId &&
        t.estado == EstadoSolicitudLimpieza.en_proceso)
      actions.add(
        TextButton(
          onPressed: () => _accion(context, () => s.finalizarLimpieza(t.id)),
          child: const Text('Marcar listo'),
        ),
      );
    return Card(
      child: ListTile(
        title: Text('Habitación ${t.habitacionId}'),
        subtitle: Text(
          '${t.descripcion ?? 'Sin descripción'} · ${t.estado.name}${t.asignadoA == null ? '' : ' · asignada'}',
        ),
        trailing: actions.isEmpty ? null : Wrap(children: actions),
      ),
    );
  }

  Widget _tarjetaMantenimiento(
    BuildContext context,
    SolicitudMantenimiento t,
    ServicioTareas s,
    bool admin,
    bool worker,
    String? userId,
  ) {
    final actions = <Widget>[];
    if (admin &&
        (t.estado == EstadoSolicitudMantenimiento.pendiente ||
            t.estado == EstadoSolicitudMantenimiento.asignada))
      actions.add(
        TextButton(
          onPressed: () async {
            final id = await _elegirEmpleado(context, RolUsuario.mantenimiento);
            if (id != null && context.mounted)
              _accion(context, () => s.asignarMantenimiento(t.id, id));
          },
          child: const Text('Asignar'),
        ),
      );
    if (worker && t.estado == EstadoSolicitudMantenimiento.pendiente)
      actions.add(
        TextButton(
          onPressed: () => _accion(context, () => s.aceptarMantenimiento(t.id)),
          child: const Text('Aceptar'),
        ),
      );
    if (worker &&
        t.asignadoA == userId &&
        (t.estado == EstadoSolicitudMantenimiento.asignada ||
            t.estado == EstadoSolicitudMantenimiento.aceptada))
      actions.add(
        TextButton(
          onPressed: () => _accion(context, () => s.iniciarMantenimiento(t.id)),
          child: const Text('Iniciar'),
        ),
      );
    if (worker &&
        t.asignadoA == userId &&
        t.estado == EstadoSolicitudMantenimiento.en_proceso)
      actions.add(
        TextButton(
          onPressed: () =>
              _accion(context, () => s.finalizarMantenimiento(t.id)),
          child: const Text('Resolver'),
        ),
      );
    return Card(
      child: ListTile(
        title: Text('Habitación ${t.habitacionId}'),
        subtitle: Text('${t.descripcion} · ${t.estado.name}'),
        trailing: actions.isEmpty ? null : Wrap(children: actions),
      ),
    );
  }
}
