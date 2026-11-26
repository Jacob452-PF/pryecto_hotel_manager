import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/servicio_sesion.dart';
import '../servicios/servicio_tareas.dart';
import '../utilidades/tiempo_hotel.dart';
import 'pantalla_factura_temporal.dart';
import 'pantalla_finalizar_estadia.dart';
import '../widgets/fila_informacion.dart';
import '../widgets/tarjeta_seccion.dart';

/// Detalle de una habitación: foto, estado, tipo, camas, huésped y acciones.
/// Recibe solo el número y busca la habitación actual, así siempre muestra
/// el estado más reciente.
class PantallaDetalleHabitacion extends StatelessWidget {
  final String numeroHabitacion;
  const PantallaDetalleHabitacion({super.key, required this.numeroHabitacion});

  Future<void> _solicitarMantenimiento(
    BuildContext context,
    String numero,
  ) async {
    final descripcion = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar mantenimiento'),
        content: TextField(
          controller: descripcion,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Describe el problema'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, descripcion.text),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    descripcion.dispose();
    if (texto == null || texto.trim().isEmpty || !context.mounted) return;
    try {
      await ServicioTareas.instancia.solicitarMantenimiento(numero, texto);
    } on Object catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
    }
  }

  Future<void> _solicitarLimpieza(BuildContext context, String numero) async {
    try {
      await ServicioTareas.instancia.solicitarLimpieza(numero);
    } on Object catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
    }
  }

  /// Los botones dependen del estado actual de la habitación.
  List<Widget> _acciones(BuildContext context, Habitacion habitacion) {
    final usuario = ServicioSesion.instancia.usuario;
    final recepcionOAdmin =
        usuario?.rol == RolUsuario.recepcion ||
        usuario?.rol == RolUsuario.admin;
    final botonMantenimiento = OutlinedButton.icon(
      onPressed:
          !recepcionOAdmin ||
              habitacion.estado == EstadoHabitacion.ocupada ||
              habitacion.estado == EstadoHabitacion.ocupadaYLimpieza
          ? null
          : () => _solicitarMantenimiento(context, habitacion.numero),
      icon: const Icon(Icons.build),
      label: const Text('Mantenimiento'),
    );

    return switch (habitacion.estado) {
      EstadoHabitacion.ocupada || EstadoHabitacion.ocupadaYLimpieza => [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !recepcionOAdmin || habitacion.limpiezaSolicitada
                    ? null
                    : () => _solicitarLimpieza(context, habitacion.numero),
                icon: const Icon(Icons.cleaning_services),
                label: Text(
                  habitacion.limpiezaSolicitada ? 'Solicitada' : 'Limpieza',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: botonMantenimiento),
          ],
        ),
        const SizedBox(height: 12),
        if (recepcionOAdmin)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PantallaFacturaTemporal(
                  habitacion: habitacion.numero,
                  huesped: habitacion.huesped ?? 'Huésped',
                ),
              ),
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Ver factura temporal y cargos'),
          ),
        const SizedBox(height: 12),
        if (recepcionOAdmin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PantallaFinalizarEstadia(
                  habitacion: habitacion.numero,
                  huesped: habitacion.huesped ?? 'Huésped',
                ),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Finalizar estadía y cobrar'),
          ),
      ],
      EstadoHabitacion.limpieza =>
        recepcionOAdmin
            ? [
                OutlinedButton.icon(
                  onPressed: () =>
                      _solicitarLimpieza(context, habitacion.numero),
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Crear tarea de limpieza'),
                ),
              ]
            : const [],
      EstadoHabitacion.reservada => const [],
      EstadoHabitacion.mantenimiento =>
        recepcionOAdmin
            ? [
                OutlinedButton.icon(
                  onPressed: () =>
                      _solicitarMantenimiento(context, habitacion.numero),
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Registrar tarea de mantenimiento'),
                ),
              ]
            : const [],
      EstadoHabitacion.disponible =>
        recepcionOAdmin
            ? [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _solicitarLimpieza(context, habitacion.numero),
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Limpieza'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: botonMantenimiento),
                  ],
                ),
              ]
            : const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioHabitaciones.instancia,
      builder: (context, _) {
        final habitacion = ServicioHabitaciones.instancia.buscar(
          numeroHabitacion,
        );

        if (habitacion == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habitación')),
            body: const Center(child: Text('Habitación no encontrada')),
          );
        }

        final estado = habitacion.estado;
        final usuario = ServicioSesion.instancia.usuario;
        if (usuario?.rol == RolUsuario.limpieza &&
                habitacion.asignadoLimpiezaId != usuario?.id ||
            usuario?.rol == RolUsuario.mantenimiento &&
                habitacion.asignadoMantenimientoId != usuario?.id) {
          return Scaffold(
            appBar: AppBar(title: Text('Habitación ${habitacion.numero}')),
            body: const Center(
              child: Text('Esta habitación no está asignada a tu usuario.'),
            ),
          );
        }
        final ocupada =
            estado == EstadoHabitacion.ocupada ||
            estado == EstadoHabitacion.ocupadaYLimpieza;
        String fecha(DateTime? valor) {
          if (valor == null) return '—';
          final salvador = TiempoHotel.relojElSalvador(valor);
          return '${salvador.day.toString().padLeft(2, '0')}/${salvador.month.toString().padLeft(2, '0')}/${salvador.year} ${salvador.hour.toString().padLeft(2, '0')}:${salvador.minute.toString().padLeft(2, '0')}';
        }

        return Scaffold(
          appBar: AppBar(title: Text('Habitación ${habitacion.numero}')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (usuario?.rol == RolUsuario.recepcion ||
                    usuario?.rol == RolUsuario.admin) ...[
                  TarjetaSeccion(
                    titulo: 'Datos del cliente',
                    icono: Icons.person_outline,
                    hijo: Column(
                      children: [
                        FilaInformacion(
                          icono: Icons.person,
                          etiqueta: 'Nombre',
                          valor: ocupada
                              ? (habitacion.huesped?.trim().isNotEmpty == true
                                    ? habitacion.huesped!.trim()
                                    : 'Cliente sin registrar')
                              : 'Sin cliente alojado',
                        ),
                        if (ocupada &&
                            habitacion.huespedDocumento?.isNotEmpty ==
                                true) ...[
                          const Divider(height: 1),
                          FilaInformacion(
                            icono: Icons.badge_outlined,
                            etiqueta: 'Documento',
                            valor: habitacion.huespedDocumento!,
                          ),
                        ],
                        if (ocupada &&
                            habitacion.huespedTelefono?.isNotEmpty == true) ...[
                          const Divider(height: 1),
                          FilaInformacion(
                            icono: Icons.phone_outlined,
                            etiqueta: 'Teléfono',
                            valor: habitacion.huespedTelefono!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TarjetaSeccion(
                  titulo: 'Datos de la habitación',
                  icono: Icons.meeting_room_outlined,
                  hijo: Column(
                    children: [
                      FilaInformacion(
                        icono: Icons.tag,
                        etiqueta: 'Número',
                        valor: habitacion.numero,
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: habitacion.tipoCuarto.icono,
                        etiqueta: 'Tipo',
                        valor: habitacion.tipoCuarto.etiqueta,
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: Icons.bed,
                        etiqueta: 'Camas',
                        valor:
                            '${habitacion.camas} ${habitacion.camas == 1 ? 'cama' : 'camas'}',
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: Icons.layers,
                        etiqueta: 'Piso',
                        valor: '${habitacion.piso}',
                      ),
                      if (ocupada) ...[
                        const Divider(height: 1),
                        FilaInformacion(
                          icono: Icons.login,
                          etiqueta: 'Ingreso',
                          valor: fecha(habitacion.entradaEstadia),
                        ),
                        const Divider(height: 1),
                        FilaInformacion(
                          icono: Icons.logout,
                          etiqueta: 'Salida prevista',
                          valor: fecha(habitacion.salidaEstadia),
                        ),
                        if (habitacion.nombreTarifa?.isNotEmpty == true) ...[
                          const Divider(height: 1),
                          FilaInformacion(
                            icono: Icons.payments_outlined,
                            etiqueta: 'Tarifa',
                            valor:
                                '${habitacion.nombreTarifa} · ${habitacion.precioTarifa?.toStringAsFixed(2) ?? '—'} USD',
                          ),
                        ],
                        if (habitacion.cantidadHuespedes != null) ...[
                          const Divider(height: 1),
                          FilaInformacion(
                            icono: Icons.groups_outlined,
                            etiqueta: 'Personas',
                            valor: '${habitacion.cantidadHuespedes}',
                          ),
                        ],
                        if (habitacion.notasEstadia?.isNotEmpty == true) ...[
                          const Divider(height: 1),
                          FilaInformacion(
                            icono: Icons.sticky_note_2_outlined,
                            etiqueta: 'Notas de estadía',
                            valor: habitacion.notasEstadia!,
                          ),
                        ],
                      ],
                      if (habitacion.notasHabitacion?.isNotEmpty == true) ...[
                        const Divider(height: 1),
                        FilaInformacion(
                          icono: Icons.notes,
                          etiqueta: 'Notas de habitación',
                          valor: habitacion.notasHabitacion!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Estado de la habitación',
                  icono: estado.icono,
                  hijo: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilaInformacion(
                        icono: estado.icono,
                        etiqueta: 'Estado actual',
                        valor: estado.etiqueta,
                        colorValor: estado.color,
                      ),
                      if (habitacion.limpiezaSolicitada) ...[
                        const Divider(height: 1),
                        const FilaInformacion(
                          icono: Icons.cleaning_services,
                          etiqueta: 'Limpieza',
                          valor: 'Solicitada',
                        ),
                      ],
                      const SizedBox(height: 12),
                      ..._acciones(context, habitacion),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
