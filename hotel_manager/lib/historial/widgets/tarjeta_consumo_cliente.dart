import 'package:flutter/material.dart';

import '../modelos/consumo_cliente.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import 'etiqueta_pill.dart';

/// Tarjeta de "Clientes y consumo": nombre, resumen y recuadro con las líneas.
class TarjetaConsumoCliente extends StatelessWidget {
  final ConsumoCliente consumo;
  const TarjetaConsumoCliente({super.key, required this.consumo});

  static const _estiloLinea = TextStyle(fontFamily: fuenteTitulo, fontSize: 13);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  consumo.cliente,
                  style: const TextStyle(
                    fontFamily: fuenteTitulo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              EtiquetaPill(consumo.codigo),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Productos', style: TextStyle(fontSize: 11)),
                    Text(
                      '${consumo.articulos} ${consumo.articulos == 1 ? 'Artículo' : 'Artículos'}',
                      style: const TextStyle(
                        fontFamily: fuenteTitulo,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 11)),
                  Text(
                    dinero(consumo.total),
                    style: const TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                for (final l in consumo.lineas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(l.nombre, style: _estiloLinea)),
                        SizedBox(
                          width: 64,
                          child: Text(
                            dinero(l.precio),
                            textAlign: TextAlign.right,
                            style: _estiloLinea,
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${l.cantidad}',
                            textAlign: TextAlign.right,
                            style: _estiloLinea,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
