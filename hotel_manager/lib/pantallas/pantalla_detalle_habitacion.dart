import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../servicios/servicio_habitaciones.dart';
import 'pantalla_factura_temporal.dart';
import 'pantalla_finalizar_estadia.dart';
import '../widgets/fila_informacion.dart';
import '../widgets/foto_habitacion.dart';
import '../widgets/tarjeta_seccion.dart';

/// Detalle de una habitación: foto, estado, tipo, camas, huésped y acciones.
/// Recibe solo el número y busca la habitación actual, así siempre muestra
/// el estado más reciente.
class PantallaDetalleHabitacion extends StatelessWidget {
  final String numeroHabitacion;
  const PantallaDetalleHabitacion({super.key, required this.numeroHabitacion});

  /// Los botones dependen del estado actual de la habitación.
  List<Widget> _acciones(BuildContext context, Habitacion habitacion) {
    final servicio = ServicioHabitaciones.instancia;

    final botonLista = FilledButton.icon(
      onPressed: () => servicio.marcarLista(habitacion.numero),
      icon: const Icon(Icons.check),
      label: const Text('Marcar como lista'),
    );
    final botonMantenimiento = OutlinedButton.icon(
      onPressed: habitacion.estado == EstadoHabitacion.ocupada
          ? null
          : () => servicio.enviarAMantenimiento(habitacion.numero),
      icon: const Icon(Icons.build),
      label: const Text('Mantenimiento'),
    );

    return switch (habitacion.estado) {
      EstadoHabitacion.ocupada => [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: habitacion.limpiezaSolicitada
                    ? null
                    : () => servicio.solicitarLimpieza(habitacion.numero),
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
      EstadoHabitacion.limpieza => [botonLista],
      EstadoHabitacion.mantenimiento => [botonLista],
      EstadoHabitacion.disponible => [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => servicio.solicitarLimpieza(habitacion.numero),
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Limpieza'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: botonMantenimiento),
          ],
        ),
      ],
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
        final ocupada = estado == EstadoHabitacion.ocupada;

        return Scaffold(
          appBar: AppBar(title: Text('Habitación ${habitacion.numero}')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FotoHabitacion(rutaFoto: habitacion.rutaFoto),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Información de la habitación',
                  icono: Icons.info_outline,
                  hijo: Column(
                    children: [
                      FilaInformacion(
                        icono: estado.icono,
                        etiqueta: 'Estado',
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
                      if (ocupada) ...[
                        const Divider(height: 1),
                        FilaInformacion(
                          icono: Icons.person,
                          etiqueta: 'Ocupada por',
                          valor: habitacion.huesped ?? 'Sin registrar',
                        ),
                      ],
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._acciones(context, habitacion),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}








