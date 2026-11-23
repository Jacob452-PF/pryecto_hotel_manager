import 'package:flutter/material.dart';

import '../modelos/huesped.dart';
import '../servicios/servicio_huespedes.dart';

/// Permite reutilizar un huésped previamente guardado o capturar uno nuevo.
class SelectorHuespedGuardado extends StatelessWidget {
  final String? seleccionadoId;
  final ValueChanged<Huesped?> alCambiar;

  const SelectorHuespedGuardado({
    super.key,
    required this.seleccionadoId,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioHuespedes.instancia;
    return ListenableBuilder(
      listenable: servicio,
      builder: (context, _) {
        final huespedes = servicio.huespedes;
        if (huespedes.isEmpty && servicio.error == null && !servicio.cargando) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            if (servicio.cargando) const LinearProgressIndicator(),
            if (servicio.error != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_off, color: Colors.red),
                title: Text(servicio.error!),
                trailing: IconButton(
                  tooltip: 'Reintentar',
                  onPressed: servicio.sincronizar,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            if (huespedes.isNotEmpty)
              Padding(
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
              ),
          ],
        );
      },
    );
  }
}
