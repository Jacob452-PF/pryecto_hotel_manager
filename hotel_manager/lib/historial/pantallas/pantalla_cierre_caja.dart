import 'package:flutter/material.dart';

import '../servicios/servicio_historial.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import '../widgets/boton_pildora.dart';
import '../widgets/resumen_turno.dart';
import '../widgets/seccion_tabla.dart';

/// Pantalla "Cierre de caja": revisa ventas y gastos y cierra el turno.
class PantallaCierreCaja extends StatelessWidget {
  const PantallaCierreCaja({super.key});

  Future<void> _confirmarCierre(BuildContext context) async {
    final servicio = ServicioHistorial.instancia;
    final turno = servicio.turnoActual;
    final messenger = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar turno?'),
        content: Text(
          'Se registrará el cierre de caja por ${dinero(turno.totalEnCaja)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar turno'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    // TODO: guardar el cierre en la base de datos.
    final caja = servicio.registrarCierre();
    navegador.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Caja #${caja.numero} cerrada correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turno = ServicioHistorial.instancia.turnoActual;
    final ahora = DateTime.now();

    final tarjetaFecha = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresHistorial.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fecha y hora', style: TextStyle(fontSize: 9)),
          Text(
            fechaHora(ahora),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Usuario', style: TextStyle(fontSize: 9)),
          Text(
            turno.usuario,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen de turno', style: TextStyle(fontSize: 10)),
        Row(
          children: const [
            Icon(Icons.assignment_turned_in_outlined, size: 30),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Cierre de caja',
                style: TextStyle(
                  fontFamily: fuenteTitulo,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Revisa el cierre de turno y confirma el cierre de caja',
          style: TextStyle(fontFamily: fuenteTitulo, fontSize: 14),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: ColoresHistorial.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
            ),
            // En pantallas anchas la fecha va a la derecha; en celular, abajo.
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 520) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titulo),
                      const SizedBox(width: 12),
                      SizedBox(width: 190, child: tarjetaFecha),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titulo, const SizedBox(height: 10), tarjetaFecha],
                );
              },
            ),
            const SizedBox(height: 12),
            ResumenTurno(
              ventas: turno.totalVentas,
              cantidadVentas: turno.cantidadVentas,
              gastos: turno.totalGastos,
              cantidadGastos: turno.gastos.length,
              habitacionesOcupadas: turno.habitacionesOcupadas,
              habitacionesTotal: turno.habitacionesTotal,
              totalEnCaja: turno.totalEnCaja,
            ),
            const SizedBox(height: 12),
            SeccionTabla(
              icono: Icons.shopping_cart,
              titulo: 'Detalle de ventas',
              encabezados: const ['Tipo', 'Cantidad', 'Monto'],
              filas: [
                for (final v in turno.ventas)
                  FilaTabla(
                    CeldaIcono(v.tipo.icono, v.tipo.etiqueta),
                    '${v.cantidad}',
                    dinero(v.monto),
                  ),
              ],
              etiquetaTotal: 'Total',
              total: dinero(turno.totalVentas),
            ),
            const SizedBox(height: 12),
            SeccionTabla(
              icono: Icons.receipt_long,
              titulo: 'Detalle de gastos',
              encabezados: const ['Categoría', 'Descripción', 'Monto'],
              filas: [
                for (final g in turno.gastos)
                  FilaTabla(
                    CeldaIcono(g.categoria.icono, g.categoria.etiqueta),
                    g.descripcion,
                    dinero(g.monto),
                  ),
              ],
              etiquetaTotal: 'Total gastos',
              total: dinero(turno.totalGastos),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BotonPildora(
        texto: 'Cerrar turno',
        onPressed: () => _confirmarCierre(context),
      ),
    );
  }
}
