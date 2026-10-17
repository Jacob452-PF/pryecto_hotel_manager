import 'package:flutter/material.dart';

import '../modelos/caja_cierre.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import 'etiqueta_pill.dart';

/// Tarjeta de un cierre en la lista del historial.
class TarjetaCaja extends StatelessWidget {
  final CajaCierre caja;
  final bool destacada;
  final VoidCallback onTap;

  const TarjetaCaja({
    super.key,
    required this.caja,
    required this.onTap,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: destacada
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.point_of_sale, size: 32),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Caja #${caja.numero}',
                              style: const TextStyle(
                                fontFamily: fuenteTitulo,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            dinero(caja.total),
                            style: const TextStyle(
                              fontFamily: fuenteTitulo,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaHora(caja.fecha),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.account_circle, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              caja.cajero,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const EtiquetaPill('Cierre'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
