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
  final _controladorBusqueda = TextEditingController();
  EstadoHabitacion? _estado; // null = todos
  int? _camas; // null = todas

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  // El resumen cuenta todas las habitaciones, sin importar el filtro.
  int _contar(List<Habitacion> todas, EstadoHabitacion estado) =>
      todas.where((h) => h.estado == estado).length;

  List<Habitacion> _filtrar(List<Habitacion> todas) {
    final texto = normalizarTexto(_controladorBusqueda.text);
    return todas.where((h) {
      if (_estado != null && h.estado != _estado) return false;
      if (_camas != null && h.camas != _camas) return false;
      if (texto.isNotEmpty) {
        final huesped = h.huesped;
        if (huesped == null || !normalizarTexto(huesped).contains(texto)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Se vuelve a dibujar solo cuando cambia el estado de alguna habitación.
    return ListenableBuilder(
      listenable: ServicioHabitaciones.instancia,
      builder: (context, _) {
        final todas = ServicioHabitaciones.instancia.habitaciones;

        final resumen = <DatoResumen>[
          DatoResumen('Disponibles', _contar(todas, EstadoHabitacion.disponible), ColoresApp.disponible, Icons.check_circle),
          DatoResumen('Ocupadas', _contar(todas, EstadoHabitacion.ocupada), ColoresApp.ocupada, Icons.bed),
          DatoResumen('En limpieza', _contar(todas, EstadoHabitacion.limpieza), ColoresApp.limpieza, Icons.cleaning_services),
          DatoResumen('Mantenimiento', _contar(todas, EstadoHabitacion.mantenimiento), ColoresApp.mantenimiento, Icons.build),
        ];

        final filtradas = _filtrar(todas);
        final pisos = filtradas.map((h) => h.piso).toSet().toList()..sort();

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parte 1: encabezado
                const TarjetaEncabezado(),
                // Parte 2: resumen
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: resumen.map((d) => CuadroResumen(dato: d)).toList(),
                  ),
                ),
                // Parte 3: botón nuevo huésped
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaNuevoHuesped()),
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nuevo huésped'),
                    ),
                  ),
                ),
                // Parte 4: filtro y habitaciones por piso
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Habitaciones', style: EstilosTexto.tituloSeccion),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TarjetaSeccion(
                    titulo: 'Buscar habitaciones',
                    icono: Icons.filter_list,
                    hijo: FiltroHabitaciones(
                      controladorBusqueda: _controladorBusqueda,
                      alCambiarBusqueda: (_) => setState(() {}),
                      estado: _estado,
                      alCambiarEstado: (e) => setState(() => _estado = e),
                      camas: _camas,
                      alCambiarCamas: (n) => setState(() => _camas = n),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '${filtradas.length} ${filtradas.length == 1 ? 'resultado' : 'resultados'}',
                    style: EstilosTexto.etiquetaInformacion,
                  ),
                ),
                if (filtradas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No se encontraron habitaciones con esos filtros',
                        style: EstilosTexto.textoVacio,
                      ),
                    ),
                  ),
                for (final piso in pisos) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('Piso $piso', style: EstilosTexto.subtituloSeccion),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: filtradas
                          .where((h) => h.piso == piso)
                          .map((h) => TarjetaHabitacion(habitacion: h))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}