import 'package:flutter/material.dart';

import '../modelos/huesped.dart';

/// Permite reutilizar un huésped previamente guardado o capturar uno nuevo.
class SelectorHuespedGuardado extends StatelessWidget {
  final List<Huesped> huespedes;
  final String? seleccionadoId;
  final ValueChanged<Huesped?> alCambiar;

  const SelectorHuespedGuardado({
    super.key,
    required this.huespedes,
    required this.seleccionadoId,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    if (huespedes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: seleccionadoId ?? '',
        decoration: const InputDecoration(
          labelText: 'Huésped guardado (opcional)',
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('Registrar huésped nuevo'),
          ),
          for (final huesped in huespedes)
            DropdownMenuItem(
              value: huesped.id,
              child: Text(
                '${huesped.nombre} · DUI ${huesped.dui}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (id) => alCambiar(
          id == null || id.isEmpty
              ? null
              : huespedes.where((h) => h.id == id).firstOrNull,
        ),
      ),
    );
  }
}
