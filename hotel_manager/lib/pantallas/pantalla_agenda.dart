import 'package:flutter/material.dart';

import '../modelos/reserva.dart';
import '../modelos/abono.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/servicio_reservas.dart';
import '../servicios/servicio_estadias.dart';
import '../utilidades/formato.dart';
import '../widgets/dialogo_cobro.dart';
import 'pantalla_nueva_reserva.dart';

class PantallaAgenda extends StatefulWidget {
  const PantallaAgenda({super.key});

  @override
  State<PantallaAgenda> createState() => _PantallaAgendaState();
}

class _PantallaAgendaState extends State<PantallaAgenda> {
  DateTime _mes = DateUtils.dateOnly(DateTime.now());
  DateTime _seleccionado = DateUtils.dateOnly(DateTime.now());

  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Reserva> _reservasDelDia(DateTime dia, List<Reserva> reservas) =>
      reservas
          .where(
            (r) => r.estado == EstadoReserva.activa && _mismoDia(r.inicio, dia),
          )
          .toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio));

  String _nombreHuesped(String id) {
    for (final huesped in ServicioHuespedes.instancia.huespedes) {
      if (huesped.id == id) return huesped.nombre;
    }
    return 'Huésped';
  }

  void _cambiarMes(int cantidad) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + cantidad);
      _seleccionado = _mes;
    });
  }

  Future<void> _crearEstadia(Reserva reserva) async {
    final numeroHabitacion = reserva.habitacionId;
    if (numeroHabitacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La habitación se asignará automáticamente un día antes de la reserva.'),
        ),
      );
      return;
    }
    final metodoPago = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Método de pago'),
        children: [
          for (final metodo in const ['efectivo', 'tarjeta', 'transferencia'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, metodo),
              child: Text(metodo[0].toUpperCase() + metodo.substring(1)),
            ),
        ],
      ),
    );
    if (metodoPago == null || !mounted) return;

    try {
      await ServicioReservas.instancia.registrarCheckIn(
        reserva.id,
        metodoPago: metodoPago,
      );
      await ServicioHabitaciones.instancia.sincronizar();
      final habitacion = ServicioHabitaciones.instancia.buscar(numeroHabitacion);
      await ServicioEstadias.instancia.sincronizar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entrada y cobro registrados en el servidor.'),
        ));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  Future<void> _abonarReserva(Reserva reserva) async {
    final pago = await mostrarDialogoCobro(
      context,
      saldo: reserva.saldoPendiente,
      permitirAbono: true,
    );
    if (pago == null || !mounted) return;
    try {
      await ServicioReservas.instancia.registrarAbono(
        reserva.id,
        monto: pago.monto,
        metodo: pago.metodo,
      );
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  Future<void> _abrirNuevaReserva() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaNuevaReserva()),
    );
    if (creada == true && mounted) {
      await ServicioReservas.instancia.sincronizar();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ServicioReservas.instancia,
      ServicioHuespedes.instancia,
    ]),
    builder: (context, _) {
      final reservas = ServicioReservas.instancia.reservas;
      final eventos = _reservasDelDia(_seleccionado, reservas);
      final primerDia = DateTime(_mes.year, _mes.month, 1);
      final desfase = primerDia.weekday - 1;
      final diasEnMes = DateTime(_mes.year, _mes.month + 1, 0).day;
      final totalCeldas = ((desfase + diasEnMes + 6) ~/ 7) * 7;
      final inicioCuadricula = primerDia.subtract(Duration(days: desfase));
      final colores = Theme.of(context).colorScheme;

      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ServicioReservas.instancia.sincronizar(),
            ServicioHabitaciones.instancia.sincronizar(),
          ]);
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => _cambiarMes(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_meses[_mes.month - 1].toUpperCase()} ${_mes.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: () => _cambiarMes(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final dia in _dias)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        dia,
                        style: TextStyle(
                          color: colores.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCeldas,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 48,
            ),
            itemBuilder: (context, index) {
              final dia = inicioCuadricula.add(Duration(days: index));
              final dentroDelMes = dia.month == _mes.month;
              final seleccionado = _mismoDia(dia, _seleccionado);
              final hoy = _mismoDia(dia, DateTime.now());
              final tieneReserva = reservas.any(
                (r) =>
                    r.estado == EstadoReserva.activa &&
                    _mismoDia(r.inicio, dia),
              );
              return InkWell(
                onTap: dentroDelMes
                    ? () => setState(() => _seleccionado = dia)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: seleccionado ? colores.primary : null,
                        border: hoy && !seleccionado
                            ? Border.all(color: colores.primary)
                            : null,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '${dia.day}',
                        style: TextStyle(
                          color: !dentroDelMes
                              ? colores.onSurface.withValues(alpha: .35)
                              : seleccionado
                              ? colores.onPrimary
                              : colores.onSurface,
                          fontWeight: seleccionado || hoy
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 4,
                      child: tieneReserva
                          ? Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? colores.primary
                                    : colores.tertiary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Reservas del ${_seleccionado.day} de ${_meses[_seleccionado.month - 1]}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (eventos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'No hay reservaciones para este día.',
                  style: TextStyle(color: colores.onSurfaceVariant),
                ),
              ),
            )
          else
            for (final reserva in eventos)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colores.primaryContainer,
                        child: Icon(
                          Icons.event,
                          color: colores.onPrimaryContainer,
                        ),
                      ),
                      title: Text(_nombreHuesped(reserva.huespedId)),
                      subtitle: Text(
                        '${reserva.tipoCuarto.etiqueta} · ${reserva.camas} ${reserva.camas == 1 ? 'cama' : 'camas'} solicitadas',
                      ),
                      trailing: Text(
                        TimeOfDay.fromDateTime(reserva.inicio).format(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${reserva.tarifaNombre ?? reserva.tarifa.etiqueta} × ${reserva.cantidad} · Habitación: ${reserva.habitacionId ?? 'pendiente de asignación'} · Salida: ${TimeOfDay.fromDateTime(reserva.fin).format(context)} · Total: ${formatearDinero(reserva.total)} · Abonado: ${formatearDinero(reserva.montoAbonado)} · Saldo: ${formatearDinero(reserva.saldoPendiente)}',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (reserva.saldoPendiente > .001)
                              OutlinedButton.icon(
                                onPressed: () => _abonarReserva(reserva),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Registrar abono'),
                              ),
                            FilledButton.icon(
                              onPressed: () => _crearEstadia(reserva),
                              icon: const Icon(Icons.login),
                              label: const Text('Crear estadía'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _abrirNuevaReserva,
            icon: const Icon(Icons.add),
            label: const Text('Crear reserva'),
          ),
        ],
        ),
      );
    },
  );

}
