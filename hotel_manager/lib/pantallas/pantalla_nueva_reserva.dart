import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import '../servicios/api_client.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../modelos/huesped.dart';
import '../utilidades/formato.dart';
import '../utilidades/tiempo_hotel.dart';
import '../widgets/contador_cantidad.dart';
import '../widgets/formulario_huesped.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_seccion.dart';
import '../widgets/selector_huesped_guardado.dart';

class PantallaNuevaReserva extends StatefulWidget {
  const PantallaNuevaReserva({super.key});
  @override
  State<PantallaNuevaReserva> createState() => _PantallaNuevaReservaState();
}

class _PantallaNuevaReservaState extends State<PantallaNuevaReserva> {
  final _form = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nombre = TextEditingController();
  final _dui = TextEditingController();
  final _telefono = TextEditingController();
  TipoCuarto _tipo = TipoCuarto.comun;
  final List<TarifaRemota> _tarifas = [];
  TarifaRemota? _tarifa;
  bool _cargandoTarifas = true;
  bool _actualizandoTarifas = false;
  Timer? _temporizadorTarifas;
  String? _errorTarifas;
  int _camas = 1;
  int _cantidad = 1;
  String? _huespedSeleccionadoId;
  String? _estadoGuardado;
  DateTime _inicio = TiempoHotel.relojElSalvador(
    TiempoHotel.ahoraUtc(),
  ).add(const Duration(hours: 1));
  bool _guardando = false;

  DateTime get _fin =>
      _inicio.add(Duration(hours: (_tarifa?.horas ?? 12) * _cantidad));

  int get _camasSeleccionadas => _tipo == TipoCuarto.comun ? 1 : _camas;
  double get _total => (_tarifa?.precio ?? 0) * _cantidad;
  String _soloDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  String _telefonoLocal(String valor) {
    final digitos = _soloDigitos(valor);
    return digitos.length == 11 && digitos.startsWith('503')
        ? digitos.substring(3)
        : digitos;
  }
  List<TarifaRemota> get _tarifasCompatibles => _tarifas
      .where(
        (t) =>
            t.tipoHabitacion == _tipo.valorApi &&
            t.camas == _camasSeleccionadas,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _cargarTarifas();
    _temporizadorTarifas = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _cargarTarifas(),
    );
  }

  Future<void> _cargarTarifas() async {
    if (_actualizandoTarifas) return;
    _actualizandoTarifas = true;
    final tarifaAnteriorId = _tarifa?.id;
    try {
      final response = await ApiClient.instance.rates();
      final rates = ApiClient.instance
          .listFromResponse(response)
          .map(
            (row) =>
                TarifaRemota.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _tarifas
          ..clear()
          ..addAll(rates);
        _tarifa =
            _tarifasCompatibles
                .where((tarifa) => tarifa.id == tarifaAnteriorId)
                .firstOrNull ??
            _tarifasCompatibles.firstOrNull;
        _cargandoTarifas = false;
        _errorTarifas = rates.isEmpty
            ? 'No hay tarifas activas en el servidor.'
            : null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoTarifas = false;
        _errorTarifas = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _actualizandoTarifas = false;
    }
  }

  @override
  void dispose() {
    _temporizadorTarifas?.cancel();
    _nombre.dispose();
    _dui.dispose();
    _telefono.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(
      TiempoHotel.relojElSalvador(TiempoHotel.ahoraUtc()),
    );
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_inicio).isBefore(hoy)
          ? hoy
          : DateUtils.dateOnly(_inicio),
      firstDate: hoy,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _inicio = DateTime.utc(
        fecha.year,
        fecha.month,
        fecha.day,
        _inicio.hour,
        _inicio.minute,
      );
    });
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _inicio = DateTime.utc(
        _inicio.year,
        _inicio.month,
        _inicio.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _guardar() async {
    final datosHuespedValidos = _nombre.text.trim().isNotEmpty &&
        _soloDigitos(_dui.text).length == 9 &&
        _telefonoLocal(_telefono.text).length == 8;
    if (!datosHuespedValidos) {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      // El ListView puede desmontar el formulario cuando se desplaza fuera
      // de pantalla. Valida sus campos solo después de volver a montarlo.
      _form.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa nombre, DUI y teléfono para registrar al huésped.',
          ),
        ),
      );
      return;
    }
    if (TiempoHotel.aUtc(_inicio).isBefore(TiempoHotel.ahoraUtc())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La entrada de la reserva debe ser futura.'),
        ),
      );
      return;
    }
    setState(() {
      _guardando = true;
      _estadoGuardado = 'Guardando huésped…';
    });
    try {
      final tarifa = _tarifa;
      if (tarifa == null) {
        throw StateError(
          _errorTarifas ?? 'Selecciona una tarifa del servidor.',
        );
      }
      final huespedSeleccionado = _huespedSeleccionadoId == null
          ? null
          : ServicioHuespedes.instancia.huespedes
                .where((h) => h.id == _huespedSeleccionadoId)
                .firstOrNull;
      final Huesped huesped;
      if (huespedSeleccionado != null &&
          _soloDigitos(huespedSeleccionado.dui) == _soloDigitos(_dui.text)) {
        huesped = await ServicioHuespedes.instancia.completarDatosReserva(
          huespedSeleccionado,
          nombre: _nombre.text,
          dui: _dui.text,
          telefono: _telefono.text,
        );
      } else {
        huesped = await ServicioHuespedes.instancia.obtenerOCrear(
          nombre: _nombre.text,
          dui: _dui.text,
          telefono: _telefono.text,
        );
      }
      if (mounted) {
        setState(() => _estadoGuardado = 'Guardando reserva en la agenda…');
      }
      await ServicioReservas.instancia.crear(
        huespedId: huesped.id,
        inicio: _inicio,
        fin: _fin,
        tipoCuarto: _tipo,
        camas: _camasSeleccionadas,
        cantidad: _cantidad,
        tarifaId: tarifa.id,
        tarifaNombre: tarifa.nombre,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
          _estadoGuardado = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Builder(
        builder: (context) {
          final formatoFecha = MaterialLocalizations.of(context);
          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                color: colores.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.event_available, color: colores.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Registra la preferencia y el horario. El sistema asignará una habitación compatible cuando falte un día.',
                          style: TextStyle(color: colores.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TarjetaSeccion(
                titulo: 'Datos del huésped',
                icono: Icons.person_outline,
                hijo: Column(
                  children: [
                    SelectorHuespedGuardado(
                      seleccionadoId: _huespedSeleccionadoId,
                      alCambiar: (Huesped? h) => setState(() {
                        _huespedSeleccionadoId = h?.id;
                        _nombre.text = h?.nombre ?? '';
                        _dui.text = _soloDigitos(h?.dui ?? '');
                        _telefono.text = _telefonoLocal(h?.telefono ?? '');
                      }),
                    ),
                    FormularioHuesped(
                      claveFormulario: _form,
                      controladorNombre: _nombre,
                      controladorDui: _dui,
                      controladorTelefono: _telefono,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TarjetaSeccion(
                titulo: 'Preferencias de habitación',
                icono: Icons.meeting_room_outlined,
                hijo: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectorOpciones<TipoCuarto>(
                      opciones: TipoCuarto.values,
                      seleccionada: _tipo,
                      etiqueta: (tipo) => tipo.etiqueta,
                      icono: (tipo) => tipo.icono,
                      alCambiar: (tipo) => setState(() {
                        _tipo = tipo;
                        _tarifa = _tarifasCompatibles.firstOrNull;
                        _cantidad = 1;
                      }),
                    ),
                    if (_tipo == TipoCuarto.especial) ...[
                      const SizedBox(height: 14),
                      const Text('Cantidad de camas'),
                      const SizedBox(height: 8),
                      SelectorOpciones<int>(
                        opciones: const [1, 2, 3, 4],
                        seleccionada: _camas,
                        etiqueta: (cantidad) => '$cantidad camas',
                        icono: (_) => Icons.bed_outlined,
                        alCambiar: (cantidad) => setState(() {
                          _camas = cantidad;
                          _tarifa = _tarifasCompatibles.firstOrNull;
                          _cantidad = 1;
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_cargandoTarifas)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorTarifas != null)
                      Text(
                        _errorTarifas!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (_tarifasCompatibles.isEmpty)
                      Text(
                        'No hay tarifas para ${_tipo.etiqueta.toLowerCase()} de $_camasSeleccionadas ${_camasSeleccionadas == 1 ? 'cama' : 'camas'}.',
                      )
                    else
                      SelectorOpciones<TarifaRemota>(
                        opciones: _tarifasCompatibles,
                        seleccionada: _tarifa,
                        etiqueta: (t) => t.etiquetaDuracion,
                        icono: (t) =>
                            t.horas <= 6 ? Icons.schedule : Icons.nights_stay,
                        detalle: (t) => formatearDinero(t.precio),
                        alCambiar: (t) => setState(() {
                          _tarifa = t;
                          _cantidad = 1;
                        }),
                      ),
                    const SizedBox(height: 12),
                    ContadorCantidad(
                      etiqueta: 'Bloques de tarifa',
                      valor: _cantidad,
                      alCambiar: (cantidad) => setState(() {
                        _cantidad = cantidad;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TarjetaSeccion(
                titulo: 'Entrada y salida estimada',
                icono: Icons.schedule,
                hijo: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.login),
                      title: const Text('Entrada'),
                      subtitle: Text(
                        '${formatoFecha.formatMediumDate(_inicio)} · ${formatoFecha.formatTimeOfDay(TimeOfDay.fromDateTime(_inicio))}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Elegir día',
                            onPressed: _elegirFecha,
                            icon: const Icon(Icons.calendar_month),
                          ),
                          IconButton(
                            tooltip: 'Elegir hora',
                            onPressed: _elegirHora,
                            icon: const Icon(Icons.access_time),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout),
                      title: const Text('Salida calculada'),
                      subtitle: Text(
                        '${formatoFecha.formatMediumDate(_fin)} · ${formatoFecha.formatTimeOfDay(TimeOfDay.fromDateTime(_fin))}',
                      ),
                      trailing: Text(
                        '${_tarifa?.nombre ?? 'Tarifa'} × $_cantidad',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TarjetaSeccion(
                titulo: 'Resumen de reserva',
                icono: Icons.receipt_long_outlined,
                hijo: Column(
                  children: [
                    _filaResumen(
                      'Tarifa',
                      '${_tarifa?.nombre ?? 'Sin tarifa'} × $_cantidad · ${formatearDinero(_tarifa?.precio ?? 0)} c/u',
                    ),
                    _filaResumen(
                      'Preferencia',
                      '${_tipo.etiqueta} · $_camasSeleccionadas ${_camasSeleccionadas == 1 ? 'cama' : 'camas'}',
                    ),
                    const Divider(),
                    _filaResumen(
                      'Total estimado',
                      formatearDinero(_total),
                      fuerte: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _guardando || _cargandoTarifas || _tarifa == null
                    ? null
                    : _guardar,
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available),
                label: Text(
                  _guardando
                      ? (_estadoGuardado ?? 'Guardando…')
                      : 'Crear reserva',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filaResumen(String etiqueta, String valor, {bool fuerte = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: TextStyle(fontWeight: fuerte ? FontWeight.bold : null),
              ),
            ),
            Text(
              valor,
              style: TextStyle(fontWeight: fuerte ? FontWeight.bold : null),
            ),
          ],
        ),
      );
}
