import 'package:flutter/material.dart';

import '../modelos/caja_cierre.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import '../widgets/etiqueta_pill.dart';
import '../widgets/tarjeta_consumo_cliente.dart';

/// Pantalla "Detalle de caja de cierre": resumen de la caja y consumo por cliente.
class PantallaDetalleCaja extends StatelessWidget {
  final CajaCierre caja;
  const PantallaDetalleCaja({super.key, required this.caja});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresHistorial.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            // Barra superior
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                const Expanded(
                  child: Text(
                    'Detalle de caja de cierre',
                    style: TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Resumen de la caja
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColoresHistorial.azulClaro,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColoresHistorial.borde),
              ),
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
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        dinero(caja.total),
                        style: const TextStyle(
                          fontFamily: fuenteTitulo,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fechaHora(caja.fecha),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          caja.cajero,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const EtiquetaPill('Cerrada'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Título de la sección
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColoresHistorial.borde),
                    ),
                    child: const Text(
                      'Clientes y consumo',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (caja.clientes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Esta caja no tiene detalle de clientes guardado.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            for (final c in caja.clientes) TarjetaConsumoCliente(consumo: c),
          ],
        ),
      ),
    );
  }
}
