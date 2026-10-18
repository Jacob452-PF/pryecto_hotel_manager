import 'dart:async';

import 'package:flutter/material.dart';

import '../servicios/servicio_estadias.dart';
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
    ServicioEstadias.instancia.asegurarEstadiaPredeterminada(
      widget.habitacion,
    );
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
    listenable: ServicioEstadias.instancia,
    builder: (context, _) {
      final e = ServicioEstadias.instancia.buscar(widget.habitacion);
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los cargos se actualizan al cargar productos desde la tienda.',
                  ),
                ],
              ),
      );
    },
  );

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
