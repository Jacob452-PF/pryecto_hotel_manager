import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../servicios/servicio_habitaciones.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/texto.dart';
import '../widgets/cuadro_resumen.dart';
import '../widgets/filtro_habitaciones.dart';
import '../widgets/tarjeta_encabezado.dart';
import '../widgets/tarjeta_habitacion.dart';
import '../widgets/tarjeta_seccion.dart';
import 'pantalla_nuevo_huesped.dart';

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
        final todas = ServicioHabitaciones.instancia.habitaciones;
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
            _contar(todas, EstadoHabitacion.ocupada),
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
        ];

        return Scaffold(
          body: Column(
            children: [
              const TarjetaEncabezado(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaNuevoHuesped()),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo huésped'),
          ),
        );
      },
    );
  }
}
