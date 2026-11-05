import 'package:flutter/material.dart';

import '../servicios/servicio_caja.dart';
import '../widgets/formulario_desglose_efectivo.dart';

class PantallaAperturaCaja extends StatelessWidget {
  const PantallaAperturaCaja({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Abrir caja')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormularioDesgloseEfectivo(
        titulo: 'Desglose de apertura (USD)',
        boton: 'Confirmar apertura',
        alCancelar: () => Navigator.pop(context),
        alConfirmar: (d) async {
          try {
            final c = await ServicioCaja.instancia.abrir(d);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Caja abierta con ${c.montoApertura.toStringAsFixed(2)} USD.',
                  ),
                ),
              );
            }
          } on Object catch (e) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Bad state: ', '')),
                ),
              );
          }
        },
      ),
    ),
  );
}
