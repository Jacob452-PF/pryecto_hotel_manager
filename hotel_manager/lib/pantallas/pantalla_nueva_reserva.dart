import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../tema/estilos_texto.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_seccion.dart';

class PantallaNuevaReserva extends StatefulWidget {
  const PantallaNuevaReserva({super.key});
  @override
  State<PantallaNuevaReserva> createState() => _PantallaNuevaReservaState();
}

class _PantallaNuevaReservaState extends State<PantallaNuevaReserva> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController(),
      _dui = TextEditingController(),
      _telefono = TextEditingController();
  String? _habitacion;
  DateTime _inicio = DateTime.now(),
      _fin = DateTime.now().add(const Duration(days: 1));
  bool _guardando = false;
  @override
  void dispose() {
    _nombre.dispose();
    _dui.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _fecha(bool inicio) async {
    final actual = inicio ? _inicio : _fin;
    final primeraFecha = inicio
        ? DateUtils.dateOnly(DateTime.now())
        : DateUtils.dateOnly(_inicio);
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual.isBefore(primeraFecha) ? primeraFecha : actual,
      firstDate: primeraFecha,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (fecha == null || !mounted) return;
    final DateTime seleccion = inicio
        ? DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            _inicio.hour,
            _inicio.minute,
          )
        : DateTime(fecha.year, fecha.month, fecha.day, _fin.hour, _fin.minute);
    if (!inicio && !seleccion.isAfter(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La salida debe ser posterior a la entrada.'),
        ),
      );
      return;
    }
    setState(() {
      if (inicio) {
        _inicio = seleccion;
        if (!_fin.isAfter(_inicio)) _fin = _inicio.add(const Duration(days: 1));
      } else {
        _fin = seleccion;
      }
    });
  }

  Future<void> _hora(bool inicio) async {
    final actual = inicio ? _inicio : _fin;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual.hour, minute: actual.minute),
    );
    if (hora == null || !mounted) return;
    setState(() {
      final fecha = inicio ? _inicio : _fin;
      final ajustada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
      if (inicio) {
        _inicio = ajustada;
      } else {
        if (!ajustada.isAfter(_inicio)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La hora de salida debe ser posterior a la entrada.',
              ),
            ),
          );
        } else {
          _fin = ajustada;
        }
      }
      if (inicio && !_fin.isAfter(_inicio)) {
        _fin = _inicio.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate() || _habitacion == null) return;
    if (!_fin.isAfter(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La salida debe ser posterior a la entrada.'),
        ),
      );
      return;
    }
    if (_inicio.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La entrada de la reserva debe ser una fecha y hora futuras.',
          ),
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final huesped = await ServicioHuespedes.instancia.obtenerOCrear(
        nombre: _nombre.text,
        dui: _dui.text,
        telefono: _telefono.text,
      );
      await ServicioReservas.instancia.crear(
        huespedId: huesped.id,
        habitacionId: _habitacion!,
        inicio: _inicio,
        fin: _fin,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libres = ServicioHabitaciones.instancia.habitaciones
        .where((h) => h.estado == EstadoHabitacion.disponible)
        .toList();
    Habitacion? seleccionada = _habitacion == null
        ? null
        : libres.where((h) => h.numero == _habitacion).firstOrNull;
    if (_habitacion != null && seleccionada == null) {
      _habitacion = null;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del huésped',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
            ),
            TextFormField(
              controller: _dui,
              decoration: const InputDecoration(labelText: 'DUI'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa el DUI' : null,
            ),
            TextFormField(
              controller: _telefono,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TarjetaSeccion(
              titulo: 'Habitaciones disponibles',
              icono: Icons.door_front_door,
              hijo: libres.isEmpty
                  ? const Text(
                      'No hay habitaciones disponibles',
                      style: EstilosTexto.textoVacio,
                    )
                  : SelectorOpciones<Habitacion>(
                      opciones: libres,
                      seleccionada: seleccionada,
                      etiqueta: (h) => 'Hab. ${h.numero}',
                      icono: (h) => h.tipoCuarto.icono,
                      detalle: (h) => 'Piso ${h.piso}',
                      alCambiar: (h) => setState(() => _habitacion = h.numero),
                    ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Entrada'),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(_inicio)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_inicio))}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Elegir fecha',
                    onPressed: () => _fecha(true),
                    icon: const Icon(Icons.calendar_month),
                  ),
                  IconButton(
                    tooltip: 'Elegir hora',
                    onPressed: () => _hora(true),
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
              onTap: () => _fecha(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Salida'),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(_fin)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_fin))}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Elegir fecha',
                    onPressed: () => _fecha(false),
                    icon: const Icon(Icons.calendar_month),
                  ),
                  IconButton(
                    tooltip: 'Elegir hora',
                    onPressed: () => _hora(false),
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
              onTap: () => _fecha(false),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.event_available),
              label: Text(_guardando ? 'Guardando…' : 'Crear reserva'),
            ),
          ],
        ),
      ),
    );
  }
}
