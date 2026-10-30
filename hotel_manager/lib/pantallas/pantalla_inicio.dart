import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/servicio_sesion.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/texto.dart';
import '../widgets/cuadro_resumen.dart';
import '../widgets/filtro_habitaciones.dart';
import '../widgets/tarjeta_encabezado.dart';
import '../widgets/tarjeta_habitacion.dart';
import '../widgets/tarjeta_seccion.dart';
import 'pantalla_nuevo_huesped.dart';
import 'pantalla_nueva_reserva.dart';
import 'pantalla_tareas.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends State<PantallaInicio> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busqueda = '';
  EstadoHabitacion? _estado;
  int? _camas;

  Future<void> _abrirRegistro() async {
    final reserva = await showModalBottomSheet<bool>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Registrar estadía'),
              onTap: () => Navigator.pop(contexto, false),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Crear reserva'),
              onTap: () => Navigator.pop(contexto, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || reserva == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => reserva
            ? const PantallaNuevaReserva()
            : const PantallaNuevoHuesped(),
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  int _contar(List<Habitacion> habitaciones, EstadoHabitacion estado) {
    return habitaciones
        .where((habitacion) => habitacion.estado == estado)
        .length;
  }

  List<Habitacion> _filtrar(List<Habitacion> habitaciones) {
    final busqueda = normalizarTexto(_busqueda);

    return habitaciones.where((habitacion) {
      final coincideBusqueda =
          busqueda.isEmpty ||
          normalizarTexto(habitacion.numero).contains(busqueda) ||
          normalizarTexto(habitacion.huesped ?? '').contains(busqueda);
      final coincideEstado = _estado == null || habitacion.estado == _estado;
      final coincideCamas = _camas == null || habitacion.camas == _camas;

      return coincideBusqueda && coincideEstado && coincideCamas;
    }).toList();
  }

  Map<int, List<Habitacion>> _agruparPorPiso(List<Habitacion> habitaciones) {
    final agrupadas = <int, List<Habitacion>>{};
    for (final habitacion in habitaciones) {
      agrupadas.putIfAbsent(habitacion.piso, () => []).add(habitacion);
    }

    return Map.fromEntries(
      agrupadas.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioHabitaciones.instancia,
      builder: (context, _) {
        final sesion = ServicioSesion.instancia.usuario;
        final todas = ServicioHabitaciones.instancia.habitaciones.where((h) {
          if (sesion?.rol == RolUsuario.limpieza) {
            return h.asignadoLimpiezaId == sesion?.id;
          }
          if (sesion?.rol == RolUsuario.mantenimiento) {
            return h.asignadoMantenimientoId == sesion?.id;
          }
          return true;
        }).toList();
        final filtradas = _filtrar(todas);
        final habitacionesPorPiso = _agruparPorPiso(filtradas);

        final resumen = [
          DatoResumen(
            'Disponibles',
            _contar(todas, EstadoHabitacion.disponible),
            ColoresApp.disponible,
            Icons.check_circle,
          ),
          DatoResumen(
            'Ocupadas',
            _contar(todas, EstadoHabitacion.ocupada) +
                _contar(todas, EstadoHabitacion.ocupadaYLimpieza),
            ColoresApp.ocupada,
            Icons.bed,
          ),
          DatoResumen(
            'En limpieza',
            _contar(todas, EstadoHabitacion.limpieza),
            ColoresApp.limpieza,
            Icons.cleaning_services,
          ),
          DatoResumen(
            'Mantenimiento',
            _contar(todas, EstadoHabitacion.mantenimiento),
            ColoresApp.mantenimiento,
            Icons.build,
          ),
          DatoResumen(
            'Reservadas',
            _contar(todas, EstadoHabitacion.reservada),
            ColoresApp.reservada,
            Icons.event,
          ),
        ];

        return Scaffold(
          body: Column(
            children: [
              const TarjetaEncabezado(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (sesion?.rol == RolUsuario.admin ||
                        sesion?.rol == RolUsuario.recepcion)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PantallaTareas(),
                            ),
                          ),
                          icon: const Icon(Icons.assignment),
                          label: const Text('Ver solicitudes y tareas'),
                        ),
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final dato in resumen) CuadroResumen(dato: dato),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TarjetaSeccion(
                      titulo: 'Habitaciones',
                      icono: Icons.hotel,
                      hijo: FiltroHabitaciones(
                        controladorBusqueda: _controladorBusqueda,
                        alCambiarBusqueda: (valor) =>
                            setState(() => _busqueda = valor),
                        estado: _estado,
                        alCambiarEstado: (valor) =>
                            setState(() => _estado = valor),
                        camas: _camas,
                        alCambiarCamas: (valor) =>
                            setState(() => _camas = valor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filtradas.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No hay habitaciones con esos filtros',
                            style: EstilosTexto.textoVacio,
                          ),
                        ),
                      )
                    else
                      for (final piso in habitacionesPorPiso.entries) ...[
                        TarjetaSeccion(
                          titulo: 'Piso ${piso.key}',
                          icono: Icons.layers,
                          hijo: SizedBox(
                            height: 126,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final habitacion in piso.value)
                                  TarjetaHabitacion(habitacion: habitacion),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton:
              sesion?.rol == RolUsuario.recepcion ||
                  sesion?.rol == RolUsuario.admin
              ? FloatingActionButton.extended(
                  onPressed: _abrirRegistro,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuevo huésped'),
                )
              : null,
        );
      },
    );
  }
}
