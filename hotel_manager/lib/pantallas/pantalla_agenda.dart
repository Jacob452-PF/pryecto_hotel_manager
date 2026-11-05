import 'package:flutter/material.dart';

import '../modelos/reserva.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../utilidades/formato.dart';

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

      return ListView(
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
                          '${reserva.tarifa.etiqueta} · ${reserva.cantidad} ${reserva.tarifa.unidad(reserva.cantidad)} · ${TimeOfDay.fromDateTime(reserva.fin).format(context)} · Total estimado: ${formatearDinero(reserva.total)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      );
    },
  );

}
