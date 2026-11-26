import 'package:flutter/material.dart';

import '../modelos/consumo_cliente.dart';
import '../servicios/servicio_consumos.dart';
import '../servicios/servicio_historial.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import '../../utilidades/tiempo_hotel.dart';
import '../widgets/aviso_ediciones_gastos.dart';
import '../widgets/boton_pildora.dart';
import '../widgets/resumen_turno.dart';
import '../widgets/seccion_tabla.dart';
import '../widgets/tarjeta_consumo_cliente.dart';
import '../../modelos/caja.dart';
import '../../servicios/servicio_caja.dart';
import '../../widgets/formulario_desglose_efectivo.dart';
import '../../servicios/servicio_abonos.dart';
import '../../widgets/dialogo_cobro.dart';
import '../modelos/turno_caja.dart';

/// Pantalla "Cierre de caja": revisa ventas, gastos y los clientes del turno
/// (quiénes ya pagaron y quiénes no), y cierra el turno.
class PantallaCierreCaja extends StatefulWidget {
  const PantallaCierreCaja({super.key});

  @override
  State<PantallaCierreCaja> createState() => _PantallaCierreCajaState();
}

class _PantallaCierreCajaState extends State<PantallaCierreCaja> {
  late final Future<void> _cargaInicial = ServicioCaja.instancia.sincronizar();

  Future<void> _confirmarCierre(BuildContext context) async {
    final cajaService = ServicioCaja.instancia;
    try {
      await cajaService.sincronizar();
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo actualizar la caja: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (cajaService.cajaActual == null || cajaService.resumenServidor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servidor no devolvió una caja abierta con su resumen. Actualiza o vuelve a iniciar la caja.',
          ),
        ),
      );
      return;
    }
    final servicio = ServicioHistorial.instancia;
    final turno = servicio.turnoActual;
    final efectivoDelTurno =
        ServicioAbonos.instancia.efectivoRecibidoEnCaja(
          cajaService.cajaActual?.id ?? '',
        ) -
        turno.gastosTotales;
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
          'registrará el efectivo esperado de ${dinero(cajaService.esperadoAlCerrar(efectivoDelTurno))}.'
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

    if (confirmar != true || !context.mounted) return;
    if (cajaService.cajaActual == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Abre una caja antes de cerrar el turno.'),
        ),
      );
      return;
    }
    final conteo = await showDialog<DesgloseEfectivo>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: FormularioDesgloseEfectivo(
            titulo: 'Desglose de cierre (USD)',
            boton: 'Continuar al cierre',
            montoEsperado: cajaService.esperadoAlCerrar(efectivoDelTurno),
            alCancelar: () => Navigator.pop(ctx),
            alConfirmar: (d) => Navigator.pop(ctx, d),
          ),
        ),
      ),
    );
    if (conteo == null || !context.mounted) return;
    final esperado = cajaService.esperadoAlCerrar(efectivoDelTurno);
    final diferencia = ((conteo.total - esperado) * 100).round() / 100;
    var confirmarDiferencia = diferencia == 0;
    if (diferencia != 0) {
      confirmarDiferencia =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Diferencia de caja'),
              content: Text(
                'Esperado: ${dinero(esperado)}\nContado: ${dinero(conteo.total)}\nDiferencia: ${dinero(diferencia)}. ¿Confirmas el cierre con esta diferencia?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Revisar conteo'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmar diferencia'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!confirmarDiferencia || !context.mounted) return;
    final cierreAt = TiempoHotel.ahoraUtc();
    final cajaCerrada = await cajaService.cerrar(
      desglose: conteo,
      netoTurno: efectivoDelTurno,
      confirmarDiferencia: true,
      cierreAt: cierreAt,
    );
    final caja = servicio.registrarCierre(
      numero: cajaCerrada.id,
      totalRegistrado: cajaCerrada.montoCierre,
      aperturaAt: cajaCerrada.aperturaAt,
      cierreAt: cajaCerrada.cierreAt ?? cierreAt,
    );
    navegador.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Caja #${caja.numero} cerrada correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se redibuja sola si se registra un cliente o cambia el turno.
    return FutureBuilder<void>(
      future: _cargaInicial,
      builder: (context, snapshot) => AnimatedBuilder(
        animation: Listenable.merge([
          ServicioConsumos.instancia,
          ServicioHistorial.instancia,
          ServicioCaja.instancia,
          ServicioAbonos.instancia,
        ]),
        builder: (context, _) => _construir(context),
      ),
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

  Widget _resumenPersistido(BuildContext context) {
    final caja = ServicioCaja.instancia;
    final resumen = caja.resumenServidor;
    final ventas = caja.ventasServidor;
    final gastos = caja.gastosServidor;
    final compras = caja.comprasServidor;
    double importe(Map<String, dynamic> fila, String campo) =>
        double.tryParse(fila[campo]?.toString() ?? '') ?? 0;
    String detalleLineas(dynamic valor) {
      if (valor is! List || valor.isEmpty) return '';
      return valor
          .whereType<Map>()
          .map((linea) {
            final producto = linea['product'] is Map
                ? (linea['product'] as Map)['name']?.toString()
                : null;
            final nombre = producto ?? linea['name']?.toString() ?? 'Artículo';
            return '$nombre × ${linea['quantity'] ?? 1}';
          })
          .join(', ');
    }

    String fecha(dynamic valor) {
      final instante = DateTime.tryParse(valor?.toString() ?? '');
      if (instante == null) return '';
      final local = TiempoHotel.relojElSalvador(instante);
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    final color = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Movimientos desde la apertura',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar movimientos',
                  onPressed: caja.sincronizando ? null : caja.sincronizar,
                  icon: caja.sincronizando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (resumen == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No se pudo cargar el resumen de caja del servidor.',
                ),
              )
            else ...[
              Text(
                'Caja abierta: ${fecha(caja.cajaActual?.aperturaAt.toIso8601String())} · ${ventas.length} ventas',
                style: TextStyle(color: color.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _filaImporte(
                'Efectivo inicial',
                importe(resumen, 'opening_amount'),
              ),
              _filaImporte(
                'Ventas en efectivo',
                importe(resumen, 'cash_sales'),
              ),
              _filaImporte(
                'Ventas con tarjeta',
                importe(resumen, 'card_sales'),
              ),
              _filaImporte(
                'Ventas por transferencia',
                importe(resumen, 'transfer_sales'),
              ),
              _filaImporte(
                'Ventas totales',
                importe(resumen, 'cash_sales') +
                    importe(resumen, 'card_sales') +
                    importe(resumen, 'transfer_sales'),
              ),
              _filaImporte('Gastos', importe(resumen, 'expenses')),
              _filaImporte(
                'Compras de inventario',
                importe(resumen, 'inventory_purchases'),
              ),
              const Divider(),
              _filaImporte(
                'Efectivo esperado',
                importe(resumen, 'expected_amount'),
                destacado: true,
              ),
              if (caja.datosTurnoServidor?['opening_breakdown'] is Map) ...[
                const SizedBox(height: 8),
                const Text('Desglose registrado al abrir'),
                for (final e in DesgloseEfectivo.fromJson(
                  Map<String, dynamic>.from(
                    caja.datosTurnoServidor!['opening_breakdown'] as Map,
                  ),
                ).valores.entries.where((e) => e.value > 0))
                  _filaImporte(e.key, e.value),
                if ((caja.datosTurnoServidor!['opening_breakdown']
                            as Map)['montoNoDesglosado']
                        is num &&
                    ((caja.datosTurnoServidor!['opening_breakdown']
                                as Map)['montoNoDesglosado']
                            as num) >
                        0)
                  _filaImporte(
                    'Otro efectivo inicial',
                    ((caja.datosTurnoServidor!['opening_breakdown']
                                as Map)['montoNoDesglosado']
                            as num)
                        .toDouble(),
                  ),
              ],
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Detalle de ventas (${ventas.length})'),
                children: [
                  if (ventas.isEmpty)
                    const ListTile(
                      title: Text('No hay ventas registradas en esta caja.'),
                    ),
                  for (final venta in ventas)
                    ListTile(
                      dense: true,
                      title: Text(
                        '${venta['customer_name'] ?? (venta['guest'] is Map ? (venta['guest'] as Map)['name'] : null) ?? venta['concept'] ?? 'Venta'} · ${dinero(importe(venta, 'total'))}',
                      ),
                      subtitle: Text(
                        '${fecha(venta['created_at'])} · ${venta['payment_method'] ?? ''} · ${venta['concept'] ?? ''}${detalleLineas(venta['items']).isEmpty ? '' : '\n${detalleLineas(venta['items'])}'}',
                      ),
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Gastos (${gastos.length})'),
                children: [
                  if (gastos.isEmpty)
                    const ListTile(title: Text('No hay gastos registrados.')),
                  for (final gasto in gastos)
                    ListTile(
                      dense: true,
                      title: Text(gasto['description']?.toString() ?? 'Gasto'),
                      subtitle: Text(fecha(gasto['created_at'])),
                      trailing: Text(dinero(importe(gasto, 'amount'))),
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Compras de inventario (${compras.length})'),
                children: [
                  if (compras.isEmpty)
                    const ListTile(
                      title: Text('No hay compras asociadas a esta caja.'),
                    ),
                  for (final compra in compras)
                    ListTile(
                      dense: true,
                      title: Text(
                        (compra['supplier'] is Map
                                    ? (compra['supplier'] as Map)['name']
                                    : null)
                                ?.toString() ??
                            'Compra de inventario',
                      ),
                      subtitle: Text(
                        '${fecha(compra['created_at'])}${detalleLineas(compra['items']).isEmpty ? '' : '\n${detalleLineas(compra['items'])}'}',
                      ),
                      trailing: Text(dinero(importe(compra, 'total'))),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filaImporte(String titulo, double monto, {bool destacado = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: destacado
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
            Text(
              dinero(monto),
              style: destacado
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ],
        ),
      );

  Widget _construir(BuildContext context) {
    final turno = ServicioHistorial.instancia.turnoActual;
    final cajaActual = ServicioCaja.instancia.cajaActual;
    final ahora = TiempoHotel.relojElSalvador(TiempoHotel.ahoraUtc());
    double resumenNumero(String key, double alternativo) =>
        double.tryParse(
          ServicioCaja.instancia.resumenServidor?[key]?.toString() ?? '',
        ) ??
        alternativo;
    final cobrosEnEfectivo = resumenNumero(
      'cash_sales',
      ServicioAbonos.instancia.efectivoRecibidoEnCaja(cajaActual?.id ?? ''),
    );
    final comprasServidor = resumenNumero(
      'inventory_purchases',
      turno.totalGastosInventario,
    );
    final gastosServidor = resumenNumero('expenses', turno.totalGastos);
    final ventasServidor = ServicioCaja.instancia.ventasServidor;
    final comprasDetalle = ServicioCaja.instancia.comprasServidor;
    final gastosDetalle = ServicioCaja.instancia.gastosServidor;
    final totalVentasServidor =
        resumenNumero('cash_sales', turno.totalVentas) +
        resumenNumero('card_sales', 0) +
        resumenNumero('transfer_sales', 0);
    final efectivoEsperado = ServicioCaja.instancia.esperadoAlCerrar(
      cobrosEnEfectivo - turno.gastosTotales,
    );

    final pendientes = turno.clientes.where((c) => !c.pagado).toList();
    final pagados = turno.clientes.where((c) => c.pagado).toList();
    double suma(List<ConsumoCliente> l) => l.fold(0.0, (s, c) => s + c.total);
    String fechaTabla(dynamic valor) {
      final instante = DateTime.tryParse(valor?.toString() ?? '');
      if (instante == null) return '—';
      final local = TiempoHotel.relojElSalvador(instante);
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    Widget tarjeta(ConsumoCliente c) => TarjetaConsumoCliente(
      consumo: c,
      onCambiarPago: c.pagado ? null : () => _registrarAbono(context, c),
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
          const Text('Fecha', style: TextStyle(fontSize: 9)),
          Text(
            fechaLarga(ahora),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Inicio de caja', style: TextStyle(fontSize: 9)),
          Text(
            cajaActual == null ? 'No disponible' : hora(cajaActual.aperturaAt),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Hora de cierre', style: TextStyle(fontSize: 9)),
          Text(
            hora(ahora),
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
            // En pantallas anchas la fecha y el desglose comparten una fila.
            LayoutBuilder(
              builder: (context, c) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titulo,
                    const SizedBox(height: 10),
                    if (c.maxWidth >= 380)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: tarjetaFecha),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DesgloseCaja(
                                apertura: cajaActual?.montoApertura ?? 0,
                                cobrosEnEfectivo: cobrosEnEfectivo,
                                compras: comprasServidor,
                                otrosGastos: gastosServidor,
                                esperado: efectivoEsperado,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      tarjetaFecha,
                      const SizedBox(height: 10),
                      _DesgloseCaja(
                        apertura: cajaActual?.montoApertura ?? 0,
                        cobrosEnEfectivo: cobrosEnEfectivo,
                        compras: comprasServidor,
                        otrosGastos: gastosServidor,
                        esperado: efectivoEsperado,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _resumenPersistido(context),
            const SizedBox(height: 12),
            ResumenTurno(
              ventas: totalVentasServidor,
              cantidadVentas: ventasServidor.length,
              gastos: gastosServidor + comprasServidor,
              cantidadGastos: gastosDetalle.length + comprasDetalle.length,
              habitacionesOcupadas: turno.habitacionesOcupadas,
              habitacionesTotal: turno.habitacionesTotal,
              totalEnCaja: efectivoEsperado,
            ),
            const SizedBox(height: 12),
            SeccionTabla(
              icono: Icons.shopping_cart,
              titulo: 'Detalle de ventas',
              encabezados: const ['Cliente / concepto', 'Pago', 'Monto'],
              filas: [
                for (final v in ventasServidor)
                  FilaTabla(
                    CeldaIcono(
                      Icons.receipt_long_outlined,
                      v['customer_name']?.toString() ??
                          (v['guest'] is Map
                              ? (v['guest'] as Map)['name']?.toString()
                              : null) ??
                          v['concept']?.toString() ??
                          'Venta',
                    ),
                    v['payment_method']?.toString() ?? '—',
                    dinero(double.tryParse(v['total']?.toString() ?? '') ?? 0),
                  ),
              ],
              etiquetaTotal: 'Total',
              total: dinero(totalVentasServidor),
            ),
            const SizedBox(height: 12),
            // Gastos y compras persistidos en la caja actual.
            SeccionTabla(
              icono: Icons.inventory_2_outlined,
              titulo: 'Detalle de gastos',
              encabezados: const ['Gasto / compra', 'Fecha', 'Monto'],
              filas: [
                for (final g in gastosDetalle)
                  FilaTabla(
                    CeldaIcono(
                      Icons.money_off_outlined,
                      g['description']?.toString() ?? 'Gasto',
                    ),
                    fechaTabla(g['created_at']),
                    dinero(double.tryParse(g['amount']?.toString() ?? '') ?? 0),
                  ),
                for (final g in comprasDetalle)
                  FilaTabla(
                    CeldaIcono(
                      Icons.inventory_2_outlined,
                      (g['supplier'] is Map
                                  ? (g['supplier'] as Map)['name']
                                  : null)
                              ?.toString() ??
                          'Compra de inventario',
                    ),
                    fechaTabla(g['created_at']),
                    dinero(double.tryParse(g['total']?.toString() ?? '') ?? 0),
                  ),
              ],
              etiquetaTotal: 'Total de gastos y compras',
              total: dinero(gastosServidor + comprasServidor),
            ),
            // Si se corrigió algún gasto: lo que se anotó antes y lo que quedó
            const SizedBox(height: 8),
            AvisoEdicionesGastos(gastos: turno.gastosInventario),
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
        texto: ServicioCaja.instancia.cajaActual == null
            ? 'Caja cerrada'
            : 'Cerrar turno',
        onPressed: () {
          if (ServicioCaja.instancia.cajaActual == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abre tu caja antes de cerrar el turno.'),
              ),
            );
            return;
          }
          _confirmarCierre(context);
        },
      ),
    );
  }

  Future<void> _registrarAbono(
    BuildContext context,
    ConsumoCliente cliente,
  ) async {
    final valor = await mostrarDialogoCobro(
      context,
      saldo: cliente.saldo,
      permitirAbono: true,
    );
    if (valor == null) return;
    try {
      final habitacion = cliente.codigo.replaceFirst('#', '');
      final cargos = [
        for (final l in cliente.lineas.where(
          (l) => l.tipo != TipoVenta.habitaciones,
        ))
          (nombre: l.nombre, precio: l.precio, cantidad: l.cantidad),
      ];
      final precio = cliente.lineas
          .where((l) => l.tipo == TipoVenta.habitaciones)
          .fold<double>(0, (s, l) => s + l.importe);
      await ServicioConsumos.instancia.registrarAbonoFactura(
        habitacion: habitacion,
        cliente: cliente.cliente,
        monto: valor.monto,
        metodo: valor.metodo,
        efectivoEntregado: valor.efectivoEntregado,
        precioEstadia: precio,
        cargos: cargos,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }
}

class _DesgloseCaja extends StatelessWidget {
  final double apertura;
  final double cobrosEnEfectivo;
  final double compras;
  final double otrosGastos;
  final double esperado;

  const _DesgloseCaja({
    required this.apertura,
    required this.cobrosEnEfectivo,
    required this.compras,
    required this.otrosGastos,
    required this.esperado,
  });

  String _importeConSigno(double importe, {required bool esGasto}) {
    final positivo = esGasto ? importe < 0 : importe >= 0;
    return '${positivo ? '+' : '-'} ${dinero(importe.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desglose de caja',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          _FilaDesglose(etiqueta: 'Apertura', importe: dinero(apertura)),
          _FilaDesglose(
            etiqueta: 'Ventas y habitaciones',
            importe: _importeConSigno(cobrosEnEfectivo, esGasto: false),
          ),
          _FilaDesglose(
            etiqueta: 'Productos adquiridos',
            importe: _importeConSigno(compras, esGasto: true),
          ),
          _FilaDesglose(
            etiqueta: 'Otros gastos',
            importe: _importeConSigno(otrosGastos, esGasto: true),
          ),
          const Divider(height: 12),
          _FilaDesglose(
            etiqueta: 'Debe quedar',
            importe: dinero(esperado),
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _FilaDesglose extends StatelessWidget {
  final String etiqueta;
  final String importe;
  final bool destacado;

  const _FilaDesglose({
    required this.etiqueta,
    required this.importe,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: destacado ? 10 : 9,
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
      fontFamily: destacado ? fuenteTitulo : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: 4),
          Text(importe, style: style),
        ],
      ),
    );
  }
}
