import 'package:flutter/material.dart';

/// Etiqueta "Pagado" (verde) o "Pendiente" (naranja).
class EstadoPagoPill extends StatelessWidget {
  final bool pagado;
  const EstadoPagoPill({super.key, required this.pagado});

  @override
  Widget build(BuildContext context) {
    final color = pagado ? const Color(0xFF22A559) : const Color(0xFFEF8A00);
    final fondo = pagado ? const Color(0xFFE6F6EC) : const Color(0xFFFFF3E0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pagado ? Icons.check_circle : Icons.schedule,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            pagado ? 'Pagado' : 'Pendiente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
