import 'package:flutter/material.dart';

import '../modelos/factura.dart';
import '../tema/colores_app.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';
import '../widgets/fila_informacion.dart';
import '../widgets/resumen_factura.dart';
import '../widgets/tarjeta_seccion.dart';
import '../servicios/servicio_abonos.dart';
import '../historial/servicios/servicio_consumos.dart';
import '../widgets/dialogo_cobro.dart';

/// Factura inicial que aparece al confirmar un nuevo huésped.
class PantallaFactura extends StatefulWidget {
  final Factura factura;
  const PantallaFactura({super.key, required this.factura});

  @override
  State<PantallaFactura> createState() => _PantallaFacturaState();
}

class _PantallaFacturaState extends State<PantallaFactura> {
  Future<void> _abonar() async {
    final f = widget.factura;
    final id = ServicioConsumos.instancia.facturaIdParaHabitacion(
      f.habitacion.numero,
      f.huesped,
    );
    final saldo = f.total - ServicioAbonos.instancia.abonado(id);
    final pago = await mostrarDialogoCobro(
      context,
      saldo: saldo,
      permitirAbono: true,
    );
    if (pago == null) return;
    try {
      await ServicioConsumos.instancia.registrarAbonoFactura(
        habitacion: f.habitacion.numero,
        cliente: f.huesped,
        monto: pago.monto,
        metodo: pago.metodo,
        efectivoEntregado: pago.efectivoEntregado,
        precioEstadia: f.montoEstadia,
        cargos: [
          for (final p in f.productos)
            (nombre: p.nombre, precio: p.precio, cantidad: 1),
        ],
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final factura = widget.factura;
    final habitacion = factura.habitacion;
    final id = ServicioConsumos.instancia.facturaIdParaHabitacion(
      habitacion.numero,
      factura.huesped,
    );
    final abonado = ServicioAbonos.instancia.abonado(id);
    final camas =
        '${habitacion.camas} ${habitacion.camas == 1 ? 'cama' : 'camas'}';

    final lineas = <LineaFactura>[
      LineaFactura(
        'Estadía ($camas): ${factura.cantidad} ${factura.tarifa.unidad(factura.cantidad)} '
        '× ${formatearDinero(factura.precioUnitario)}',
        factura.montoEstadia,
      ),
      for (final producto in factura.productos)
        LineaFactura(producto.nombre, producto.precio),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Factura inicial'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: ColoresApp.disponible,
                      size: 32,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reserva confirmada',
                      style: EstilosTexto.tituloSeccion,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Huésped',
                  icono: Icons.person,
                  hijo: Column(
                    children: [
                      FilaInformacion(
                        icono: Icons.badge_outlined,
                        etiqueta: 'Nombre',
                        valor: factura.huesped,
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: Icons.credit_card,
                        etiqueta: 'DUI',
                        valor: formatearDui(factura.dui),
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: Icons.phone,
                        etiqueta: 'Teléfono',
                        valor: formatearTelefono(factura.telefono),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Habitación',
                  icono: Icons.door_front_door,
                  hijo: Column(
                    children: [
                      FilaInformacion(
                        icono: Icons.meeting_room,
                        etiqueta: 'Número',
                        valor: '${habitacion.numero} (piso ${habitacion.piso})',
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: habitacion.tipoCuarto.icono,
                        etiqueta: 'Tipo',
                        valor: habitacion.tipoCuarto.etiqueta,
                      ),
                      const Divider(height: 1),
                      FilaInformacion(
                        icono: Icons.bed,
                        etiqueta: 'Camas',
                        valor: camas,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Detalle de la factura',
                  icono: Icons.receipt_long,
                  hijo: ResumenFactura(
                    detalle: 'Fecha: ${formatearFechaHora(factura.fecha)}',
                    lineas: lineas,
                    total: factura.total,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Abonado: ${formatearDinero(abonado)} · Saldo pendiente: ${formatearDinero((factura.total - abonado).clamp(0, factura.total))}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: abonado >= factura.total - .001 ? null : _abonar,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    abonado > 0
                        ? 'Agregar abono'
                        : 'Pagar una parte ahora (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al inicio'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
