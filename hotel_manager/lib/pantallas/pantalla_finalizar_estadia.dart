import 'package:flutter/material.dart';

import '../servicios/api_client.dart';
import '../servicios/servicio_estadias.dart';
import '../servicios/servicio_habitaciones.dart';
import '../utilidades/formato.dart';
import '../widgets/dialogo_cobro.dart';

class PantallaFinalizarEstadia extends StatefulWidget {
  final String habitacion;
  final String huesped;
  const PantallaFinalizarEstadia({super.key, required this.habitacion, required this.huesped});

  @override
  State<PantallaFinalizarEstadia> createState() => _PantallaFinalizarEstadiaState();
}

class _PantallaFinalizarEstadiaState extends State<PantallaFinalizarEstadia> {
  bool _pagada = false;
  bool _enviando = false;
  double _cobroFinal = 0;
  double _precioHabitacion = 0;
  String _restante = '';
  List<CargoEstadia> _cargosCobrados = [];

  @override
  void initState() {
    super.initState();
    ServicioEstadias.instancia.sincronizar();
  }

  Future<void> _finalizar(DatosEstadia estadia) async {
    if (_enviando) return;
    final saldo = estadia.saldoCargos;
    final pago = saldo > .001
        ? await mostrarDialogoCobro(context, saldo: saldo)
        : null;
    if (saldo > .001 && pago == null || !mounted) return;

    setState(() => _enviando = true);
    try {
      await ApiClient.instance.checkoutStay(
        estadia.id,
        paymentMethod: saldo > .001 ? pago!.metodo.name : null,
      );
      await Future.wait([
        ServicioHabitaciones.instancia.sincronizar(),
        ServicioEstadias.instancia.sincronizar(),
      ]);
      if (!mounted) return;
      setState(() {
        _cobroFinal = saldo;
        _precioHabitacion = estadia.precioEstadia;
        _cargosCobrados = [
          ...estadia.cargosIniciales,
          ...estadia.cargosTienda,
        ].where((charge) => !charge.pagado).toList();
        _restante = _tiempo(estadia.salida);
        _pagada = true;
      });
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_pagada ? 'Estadía finalizada' : 'Finalizar estadía')),
    body: ListenableBuilder(
      listenable: ServicioEstadias.instancia,
      builder: (context, _) {
        final estadia = ServicioEstadias.instancia.buscar(widget.habitacion);
        if (_pagada) return _resultado(context);
        if (estadia == null) {
          final servicio = ServicioEstadias.instancia;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(servicio.cargando
                      ? 'Cargando estadía del servidor…'
                      : servicio.error == null
                          ? 'No hay una estadía activa del servidor en esta habitación.'
                          : 'No se pudo cargar la estadía: ${servicio.error}'),
                  if (!servicio.cargando)
                    TextButton.icon(
                      onPressed: servicio.sincronizar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          );
        }
        final cargos = [...estadia.cargosIniciales, ...estadia.cargosTienda];
        final saldo = estadia.saldoCargos;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen de estadía', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _fila('Habitación ${widget.habitacion} · pagada al ingreso', estadia.precioEstadia),
                    for (final cargo in cargos)
                      _fila(
                        '${cargo.nombre}${cargo.cantidad > 1 ? ' × ${cargo.cantidad}' : ''}${cargo.pagado ? ' · pagado' : ''}',
                        cargo.importe,
                      ),
                    if (cargos.isEmpty) const Text('No hay cargos adicionales.'),
                    const Divider(),
                    _fila('Saldo adicional al checkout', saldo, negrita: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _enviando ? null : () => _finalizar(estadia),
              child: Text(_enviando ? 'Finalizando…' : saldo > .001 ? 'Cobrar saldo y finalizar' : 'Finalizar estadía'),
            ),
          ],
        );
      },
    ),
  );

  Widget _resultado(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 24),
      const Icon(Icons.check_circle_outline, size: 82, color: Colors.green),
      const Center(child: Text('Estadía finalizada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _fila('Habitación pagada al ingreso', _precioHabitacion),
              for (final cargo in _cargosCobrados)
                _fila('${cargo.nombre}${cargo.cantidad > 1 ? ' × ${cargo.cantidad}' : ''}', cargo.importe),
              const Divider(),
              _fila('Cobrado al finalizar', _cobroFinal, negrita: true),
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
      FilledButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Volver al inicio')),
    ],
  );

  Widget _fila(String label, double amount, {bool negrita = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: negrita ? FontWeight.bold : null))),
        Text(formatearDinero(amount), style: TextStyle(fontWeight: negrita ? FontWeight.bold : null)),
      ],
    ),
  );

  String _tiempo(DateTime salida) {
    final d = salida.difference(DateTime.now());
    if (d.isNegative) return 'Estadía vencida';
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }
}
