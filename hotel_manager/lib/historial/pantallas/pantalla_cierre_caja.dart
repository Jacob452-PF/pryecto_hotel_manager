import 'package:flutter/material.dart';

import '../modelos/consumo_cliente.dart';
import '../servicios/servicio_consumos.dart';
import '../servicios/servicio_historial.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import '../widgets/boton_pildora.dart';
import '../widgets/resumen_turno.dart';
import '../widgets/seccion_tabla.dart';
import '../widgets/tarjeta_consumo_cliente.dart';

/// Pantalla "Cierre de caja": revisa ventas, gastos y los clientes del turno
/// (quiénes ya pagaron y quiénes no), y cierra el turno.
class PantallaCierreCaja extends StatelessWidget {
  const PantallaCierreCaja({super.key});

  Future<void> _confirmarCierre(BuildContext context) async {
    final servicio = ServicioHistorial.instancia;
    final turno = servicio.turnoActual;
    final messenger = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final n = turno.clientes.length;
    final pendientes = turno.clientes.where((c) => !c.pagado).length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar turno?'),
        content: Text(
          'Se cerrará el turno con $n ${n == 1 ? 'cliente' : 'clientes'} y se '
          'registrará el cierre de caja por ${dinero(turno.totalEnCaja)}.'
          '${pendientes > 0 ? '\n\n$pendientes ${pendientes == 1 ? 'cliente no ha cancelado su cuenta y quedará' : 'clientes no han cancelado su cuenta y quedarán'} como pendiente en esta caja.' : ''}',
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
    // Se redibuja sola si se registra un cliente o cambia el turno.
    return AnimatedBuilder(
      animation: Listenable.merge([
        ServicioConsumos.instancia,
        ServicioHistorial.instancia,
      ]),
      builder: (context, _) => _construir(context),
    );
  }

  /// Encabezado de un grupo ("Pendientes de pago (2)").
  Widget _tituloGrupo(String texto, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: fuenteTitulo,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _resumenPago(
    BuildContext context,
    String titulo,
    int cantidad,
    double monto,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 2),
            Text(
              dinero(monto),
              style: const TextStyle(
                fontFamily: fuenteTitulo,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$cantidad ${cantidad == 1 ? 'cliente' : 'clientes'}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construir(BuildContext context) {
    final turno = ServicioHistorial.instancia.turnoActual;
    final ahora = DateTime.now();

    final pendientes = turno.clientes.where((c) => !c.pagado).toList();
    final pagados = turno.clientes.where((c) => c.pagado).toList();
    double suma(List<ConsumoCliente> l) => l.fold(0.0, (s, c) => s + c.total);

    Widget tarjeta(ConsumoCliente c) => TarjetaConsumoCliente(
      consumo: c,
      onCambiarPago: () =>
          ServicioConsumos.instancia.cambiarPago(c.id, !c.pagado),
    );

    final tarjetaFecha = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              gastos: turno.gastosTotales,
              cantidadGastos: turno.cantidadGastos,
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
            // SeccionTabla(
            // icono: Icons.receipt_long,
            //titulo: 'Detalle de gastos',
            // encabezados: const ['Categoría', 'Descripción', 'Monto'],
            // filas: [
            //for (final g in turno.gastos)
            //FilaTabla(
            // CeldaIcono(g.categoria.icono, g.categoria.etiqueta),
            // g.descripcion,
            //dinero(g.monto),
            // ),
            // ],
            // etiquetaTotal: 'Total gastos',
            // total: dinero(turno.totalGastos),
            // ),
            const SizedBox(height: 12),
            // Lo que el hotel gastó comprando productos o reponiendo stock
            SeccionTabla(
              icono: Icons.inventory_2_outlined,
              titulo: 'Gastos de inventario',
              encabezados: const ['Producto', 'Detalle', 'Monto'],
              filas: [
                for (final g in turno.gastosInventario)
                  FilaTabla(
                    CeldaIcono(Icons.inventory_2_outlined, g.producto),
                    g.detalle,
                    dinero(g.monto),
                  ),
              ],
              etiquetaTotal: 'Total inventario',
              total: dinero(turno.totalGastosInventario),
            ),
            const SizedBox(height: 16),
            // Clientes registrados durante el turno
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      'Clientes del día (${turno.clientes.length})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (turno.clientes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Todavía no hay clientes en este turno.\n'
                    'Registra un huésped o carga una compra desde la tienda.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              // Resumen: cuánto está cobrado y cuánto falta por cobrar
              Row(
                children: [
                  _resumenPago(
                    context,
                    'Ya pagaron',
                    pagados.length,
                    suma(pagados),
                    const Color(0xFF22A559),
                  ),
                  const SizedBox(width: 8),
                  _resumenPago(
                    context,
                    'Sin pagar',
                    pendientes.length,
                    suma(pendientes),
                    const Color(0xFFEF8A00),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (pendientes.isNotEmpty) ...[
                _tituloGrupo(
                  'Sin cancelar (${pendientes.length})',
                  const Color(0xFFEF8A00),
                ),
                for (final c in pendientes) tarjeta(c),
              ],
              if (pagados.isNotEmpty) ...[
                _tituloGrupo(
                  'Ya cancelaron (${pagados.length})',
                  const Color(0xFF22A559),
                ),
                for (final c in pagados) tarjeta(c),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: BotonPildora(
        texto: 'Cerrar turno',
        onPressed: () {
          // Sin clientes no hay nada que cerrar.
          if (turno.clientes.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay clientes que cerrar en este turno'),
              ),
            );
            return;
          }
          _confirmarCierre(context);
        },
      ),
    );
  }
}
