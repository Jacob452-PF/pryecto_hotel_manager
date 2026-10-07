import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../tema/estilos_texto.dart';

/// Filtro del home: buscar por huésped, por estado y por cantidad de camas.
/// Un valor null en estado o camas significa "todos".
class FiltroHabitaciones extends StatelessWidget {
  static const _opcionesCamas = [1, 2, 3, 4];

  final TextEditingController controladorBusqueda;
  final ValueChanged<String> alCambiarBusqueda;
  final EstadoHabitacion? estado;
  final ValueChanged<EstadoHabitacion?> alCambiarEstado;
  final int? camas;
  final ValueChanged<int?> alCambiarCamas;

  const FiltroHabitaciones({
    super.key,
    required this.controladorBusqueda,
    required this.alCambiarBusqueda,
    required this.estado,
    required this.alCambiarEstado,
    required this.camas,
    required this.alCambiarCamas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controladorBusqueda,
          onChanged: alCambiarBusqueda,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar por huésped',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controladorBusqueda.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controladorBusqueda.clear();
                      alCambiarBusqueda('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Estado', style: EstilosTexto.etiquetaInformacion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: estado == null,
              onSelected: (_) => alCambiarEstado(null),
            ),
            for (final e in EstadoHabitacion.values)
              ChoiceChip(
                avatar: Icon(e.icono, size: 18, color: e.color),
                label: Text(e.etiqueta),
                selected: estado == e,
                onSelected: (_) => alCambiarEstado(e),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Camas', style: EstilosTexto.etiquetaInformacion),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: camas == null,
              onSelected: (_) => alCambiarCamas(null),
            ),
            for (final n in _opcionesCamas)
              ChoiceChip(
                label: Text('$n ${n == 1 ? 'cama' : 'camas'}'),
                selected: camas == n,
                onSelected: (_) => alCambiarCamas(n),
              ),
          ],
        ),
      ],
    );
  }
}
