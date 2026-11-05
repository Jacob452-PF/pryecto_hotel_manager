import 'dart:async';

import 'package:flutter/material.dart';

import '../servicios/servicio_estadias.dart';
import '../servicios/servicio_abonos.dart';
import '../historial/servicios/servicio_consumos.dart';
import '../modelos/abono.dart';
import '../utilidades/formato.dart';

class PantallaFacturaTemporal extends StatefulWidget {
  final String habitacion;
  final String huesped;
  const PantallaFacturaTemporal({
    super.key,
    required this.habitacion,
    required this.huesped,
  });
  @override
  State<PantallaFacturaTemporal> createState() =>
      _PantallaFacturaTemporalState();
}

class _PantallaFacturaTemporalState extends State<PantallaFacturaTemporal> {
  Timer? _reloj;
  @override
  void initState() {
    super.initState();
    ServicioEstadias.instancia.asegurarEstadiaPredeterminada(widget.habitacion);
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  String _restante(DateTime salida) {
    final d = salida.difference(DateTime.now());
    if (d.isNegative) return 'Estadía vencida';
    final h = d.inHours, m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m restantes';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ServicioEstadias.instancia,
      ServicioAbonos.instancia,
    ]),
    builder: (context, _) {
      final e = ServicioEstadias.instancia.buscar(widget.habitacion);
      final id = ServicioConsumos.instancia.facturaIdParaHabitacion(
        widget.habitacion,
        widget.huesped,
      );
      final abonado = ServicioAbonos.instancia.abonado(id);
      final saldo = e == null
          ? 0.0
          : (e.total - abonado).clamp(0.0, e.total).toDouble();
      return Scaffold(
        appBar: AppBar(title: const Text('Factura temporal')),
        body: e == null
            ? const Center(
                child: Text('No hay cargos registrados para esta estadía.'),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habitación ${widget.habitacion} · ${widget.huesped}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(_restante(e.salida)),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value:
                                (DateTime.now()
                                            .difference(e.entrada)
                                            .inSeconds /
                                        e.salida
                                            .difference(e.entrada)
                                            .inSeconds)
                                    .clamp(0.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estadía',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          _fila('Cargo de habitación', e.precioEstadia),
                          const Divider(),
                          Text(
                            'Productos y cargos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final c in [
                            ...e.cargosIniciales,
                            ...e.cargosTienda,
                          ])
                            _fila(
                              '${c.nombre}${c.cantidad > 1 ? ' × ${c.cantidad}' : ''}',
                              c.importe,
                            ),
                          if (e.cargosIniciales.isEmpty &&
                              e.cargosTienda.isEmpty)
                            const Text('Todavía no hay productos cargados.'),
                          const Divider(),
                          _fila('Total temporal', e.total, negrita: true),
                          _fila('Abonado', abonado),
                          _fila('Saldo pendiente', saldo, negrita: true),
                          if (ServicioAbonos.instancia
                              .paraFactura(id)
                              .isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              'Abonos recibidos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            for (final a
                                in ServicioAbonos.instancia.paraFactura(id))
                              _fila(
                                '${a.metodo.name} · ${a.createdAt.toLocal().toString().substring(0, 16)}',
                                a.monto,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los cargos se actualizan al cargar productos desde la tienda.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: saldo <= 0
                        ? null
                        : () => _registrarAbono(context, id, saldo, e),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Registrar abono'),
                  ),
                ],
              ),
      );
    },
  );

  Future<void> _registrarAbono(
    BuildContext context,
    String facturaId,
    double saldo,
    DatosEstadia e,
  ) async {
    final montoCtrl = TextEditingController();
    var metodo = MetodoAbono.efectivo;
    final resultado = await showDialog<(double, MetodoAbono)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Registrar abono'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo pendiente: ${formatearDinero(saldo)}'),
              TextField(
                controller: montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monto del abono'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MetodoAbono>(
                value: metodo,
                decoration: const InputDecoration(labelText: 'Método'),
                items: [
                  for (final m in MetodoAbono.values)
                    DropdownMenuItem(value: m, child: Text(m.name)),
                ],
                onChanged: (v) {
                  if (v != null) setDialog(() => metodo = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(
                  montoCtrl.text.trim().replaceAll(',', '.'),
                );
                if (v != null) Navigator.pop(ctx, (v, metodo));
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    montoCtrl.dispose();
    if (resultado == null) return;
    try {
      final cargos = [...e.cargosIniciales, ...e.cargosTienda]
          .map(
            (c) => (nombre: c.nombre, precio: c.precio, cantidad: c.cantidad),
          )
          .toList();
      await ServicioConsumos.instancia.registrarAbonoFactura(
        habitacion: widget.habitacion,
        cliente: widget.huesped,
        monto: resultado.$1,
        metodo: resultado.$2,
        precioEstadia: e.precioEstadia,
        cargos: cargos,
      );
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
    }
  }

  Widget _fila(String titulo, double monto, {bool negrita = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(fontWeight: negrita ? FontWeight.bold : null),
          ),
        ),
        Text(
          formatearDinero(monto),
          style: TextStyle(fontWeight: negrita ? FontWeight.bold : null),
        ),
      ],
    ),
  );
}
