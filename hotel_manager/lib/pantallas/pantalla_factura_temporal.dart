import 'dart:async';

import 'package:flutter/material.dart';

import '../servicios/servicio_estadias.dart';
import '../utilidades/formato.dart';

/// Consulta la instantánea remota de la estadía. Los abonos no aplican aquí:
/// la habitación se paga al ingreso y los cargos adicionales al checkout.
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
    ServicioEstadias.instancia.sincronizar();
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
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m restantes';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Resumen de estadía')),
    body: ListenableBuilder(
      listenable: ServicioEstadias.instancia,
      builder: (context, _) {
        final service = ServicioEstadias.instancia;
        final stay = service.buscar(widget.habitacion);
        if (stay == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(service.cargando
                      ? 'Cargando datos del servidor…'
                      : service.error == null
                          ? 'No hay una estadía activa en esta habitación.'
                          : 'No se pudo cargar la estadía: ${service.error}'),
                  if (!service.cargando)
                    TextButton.icon(
                      onPressed: service.sincronizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          );
        }
        final charges = [...stay.cargosIniciales, ...stay.cargosTienda];
        final progress = stay.salida.difference(stay.entrada).inSeconds <= 0
            ? 0.0
            : DateTime.now().difference(stay.entrada).inSeconds /
                  stay.salida.difference(stay.entrada).inSeconds;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habitación ${widget.habitacion} · ${widget.huesped}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_restante(stay.salida)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
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
                    Text('Cuenta del servidor', style: Theme.of(context).textTheme.titleMedium),
                    _fila('Habitación · pagada al ingreso', stay.precioEstadia),
                    const Divider(),
                    Text('Cargos adicionales', style: Theme.of(context).textTheme.titleMedium),
                    for (final charge in charges)
                      _fila(
                        '${charge.nombre}${charge.cantidad > 1 ? ' × ${charge.cantidad}' : ''}${charge.pagado ? ' · pagado' : ''}',
                        charge.importe,
                      ),
                    if (charges.isEmpty) const Text('Todavía no hay cargos adicionales.'),
                    const Divider(),
                    _fila('Saldo adicional al checkout', stay.saldoCargos, negrita: true),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('La habitación se cobra al ingreso; los cargos pendientes se pagan al finalizar.'),
            ),
          ],
        );
      },
    ),
  );

  Widget _fila(String label, double amount, {bool negrita = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: negrita ? FontWeight.bold : null))),
        Text(formatearDinero(amount), style: TextStyle(fontWeight: negrita ? FontWeight.bold : null)),
      ],
    ),
  );
}
