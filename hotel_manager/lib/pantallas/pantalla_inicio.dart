import 'package:flutter/material.dart';
import '../datos/habitaciones_ejemplo.dart';
import '../modelos/habitacion.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../widgets/cuadro_resumen.dart';
import '../widgets/tarjeta_encabezado.dart';
import '../widgets/tarjeta_habitacion.dart';
import 'pantalla_nuevo_huesped.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends State<PantallaInicio> {
  TipoHabitacion _filtro = TipoHabitacion.estandar;

  int _contar(bool Function(Habitacion) condicion) =>
      habitacionesEjemplo.where(condicion).length;

  @override
  Widget build(BuildContext context) {
    final resumen = <DatoResumen>[
      DatoResumen('Disponibles', _contar((h) => h.estado == EstadoHabitacion.disponible), ColoresApp.disponible, Icons.check_circle),
      DatoResumen('Ocupadas estándar', _contar((h) => h.estado == EstadoHabitacion.ocupada && h.tipo == TipoHabitacion.estandar), ColoresApp.ocupadaEstandar, Icons.bed),
      DatoResumen('Ocupadas especiales', _contar((h) => h.estado == EstadoHabitacion.ocupada && h.tipo == TipoHabitacion.especial), ColoresApp.ocupadaEspecial, Icons.star),
      DatoResumen('En limpieza', _contar((h) => h.estado == EstadoHabitacion.limpieza), ColoresApp.limpieza, Icons.cleaning_services),
      DatoResumen('Mantenimiento', _contar((h) => h.estado == EstadoHabitacion.mantenimiento), ColoresApp.mantenimiento, Icons.build),
    ];

    final filtradas = habitacionesEjemplo.where((h) => h.tipo == _filtro).toList();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Text('Habitaciones', style: EstilosTexto.tituloSeccion),
                  const Spacer(),
                  SegmentedButton<TipoHabitacion>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: TipoHabitacion.estandar, label: Text('Estándar')),
                      ButtonSegment(value: TipoHabitacion.especial, label: Text('Especiales')),
                    ],
                    selected: {_filtro},
                    onSelectionChanged: (s) => setState(() => _filtro = s.first),
                  ),
                ],
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
  }
}