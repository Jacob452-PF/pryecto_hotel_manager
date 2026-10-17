import 'package:flutter/material.dart';

import '../servicios/servicio_estadias.dart';
import '../servicios/servicio_habitaciones.dart';
import '../utilidades/formato.dart';

class PantallaFinalizarEstadia extends StatefulWidget {
  final String habitacion;
  final String huesped;
  const PantallaFinalizarEstadia({
    super.key,
    required this.habitacion,
    required this.huesped,
  });
  @override
  State<PantallaFinalizarEstadia> createState() =>
      _PantallaFinalizarEstadiaState();
}

class _PantallaFinalizarEstadiaState extends State<PantallaFinalizarEstadia> {
  String? _metodo;
  bool _pagada = false;
  double _total = 0;
  double _precioHabitacion = 0;
  String _restante = '';
  List<CargoEstadia> _lineasFinales = [];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_pagada ? 'Pago realizado' : 'Finalizar estadía'),
    ),
    body: ListenableBuilder(
      listenable: ServicioEstadias.instancia,
      builder: (context, _) {
        final estadia = ServicioEstadias.instancia.buscar(widget.habitacion);
        final total = estadia?.total ?? 0;
        final lineas = estadia == null
            ? <CargoEstadia>[]
            : [...estadia.cargosIniciales, ...estadia.cargosTienda];
        if (_pagada) return _resultado(context, _lineasFinales, _total);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de pago',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _fila(
                      'Habitación ${widget.habitacion}',
                      estadia?.precioEstadia ?? 0,
                    ),
                    const SizedBox(height: 8),
                    for (final c in lineas)
                      _fila(
                        '${c.nombre}${c.cantidad > 1 ? ' × ${c.cantidad}' : ''}',
                        c.importe,
                      ),
                    if (lineas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Sin productos cargados'),
                      ),
                    const Divider(),
                    _fila('Total a pagar', total, negrita: true),
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
                      'Método de pago',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    for (final m in ['Efectivo', 'Tarjeta', 'Transferencia'])
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m),
                        value: m,
                        groupValue: _metodo,
                        onChanged: (v) => setState(() => _metodo = v),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _metodo == null
                  ? null
                  : () {
                      final e = ServicioEstadias.instancia.buscar(
                        widget.habitacion,
                      );
                      setState(() {
                        _total = e?.total ?? total;
                        _precioHabitacion = e?.precioEstadia ?? 0;
                        _lineasFinales = e == null
                            ? []
                            : [...e.cargosIniciales, ...e.cargosTienda];
                        _restante = e == null
                            ? 'Estadía finalizada'
                            : _tiempo(e.salida);
                        _pagada = true;
                      });
                      ServicioHabitaciones.instancia.terminarEstadia(
                        widget.habitacion,
                      );
                      ServicioEstadias.instancia.limpiar(widget.habitacion);
                    },
              child: const Text('Confirmar pago'),
            ),
          ],
        );
      },
    ),
  );

  Widget _resultado(
    BuildContext context,
    List<CargoEstadia> lineas,
    double total,
  ) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 24),
      const Icon(Icons.check_circle_outline, size: 82, color: Colors.green),
      const Center(
        child: Text(
          '¡Pago realizado!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      const Center(child: Text('La estadía se ha finalizado correctamente')),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _fila(
                'Habitación ${widget.habitacion}',
                _precioHabitacion,
                negrita: true,
              ),
              for (final c in lineas)
                _fila(
                  '${c.nombre}${c.cantidad > 1 ? ' × ${c.cantidad}' : ''}',
                  c.importe,
                ),
              const Divider(),
              _fila('Total pagado', _total, negrita: true),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Tiempo restante al finalizar: $_restante'),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        child: const Text('Volver al inicio'),
      ),
    ],
  );

  Widget _fila(String label, double amount, {bool negrita = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: negrita ? FontWeight.bold : null),
          ),
        ),
        Text(
          formatearDinero(amount),
          style: TextStyle(fontWeight: negrita ? FontWeight.bold : null),
        ),
      ],
    ),
  );
  String _tiempo(DateTime salida) {
    final d = salida.difference(DateTime.now());
    if (d.isNegative) return 'Estadía vencida';
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }
}
