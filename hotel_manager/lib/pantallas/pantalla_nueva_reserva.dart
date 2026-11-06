import 'package:flutter/material.dart';

import '../datos/tarifas_ejemplo.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../modelos/huesped.dart';
import '../utilidades/formato.dart';
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
  final _nombre = TextEditingController();
  final _dui = TextEditingController();
  final _telefono = TextEditingController();
  TipoCuarto _tipo = TipoCuarto.matrimonial;
  TipoTarifa _tarifa = TipoTarifa.porNoche;
  int _camas = 2;
  int _cantidad = 1;
  String? _huespedSeleccionadoId;
  DateTime _inicio = DateTime.now().add(const Duration(hours: 1));
  bool _guardando = false;

  DateTime get _fin => _inicio.add(
    _tarifa == TipoTarifa.porHora
        ? Duration(hours: _cantidad)
        : Duration(days: _cantidad),
  );

  int get _camasSeleccionadas => _tipo == TipoCuarto.familiar ? _camas : 1;
  double get _precioUnitario => tarifasEjemplo
      .firstWhere((tarifa) => tarifa.tipo == _tarifa)
      .precioPara(_camasSeleccionadas);
  double get _total => _precioUnitario * _cantidad;

  @override
  void dispose() {
    _nombre.dispose();
    _dui.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
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
      _inicio = DateTime(
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
      _inicio = DateTime(
        _inicio.year,
        _inicio.month,
        _inicio.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (_inicio.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La entrada de la reserva debe ser futura.'),
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final huesped = await ServicioHuespedes.instancia
          .obtenerOCrear(
            nombre: _nombre.text,
            dui: _dui.text,
            telefono: _telefono.text,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw StateError(
              'El guardado del huésped tardó demasiado. Revisa la conexión e inténtalo de nuevo.',
            ),
          );
      await ServicioReservas.instancia.crear(
        huespedId: huesped.id,
        inicio: _inicio,
        fin: _fin,
        total: _total,
        tipoCuarto: _tipo,
        camas: _camasSeleccionadas,
        tarifa: _tarifa,
        cantidad: _cantidad,
      );
      if (!mounted) return;
      if (mounted) Navigator.pop(context, true);
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
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Builder(
        builder: (context) {
          final formatoFecha = MaterialLocalizations.of(context);
          return ListView(
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
                          'Registra los datos del huésped y lo que necesita. No se asignará una habitación en esta solicitud.',
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
                      huespedes: ServicioHuespedes.instancia.huespedes,
                      seleccionadoId: _huespedSeleccionadoId,
                      alCambiar: (Huesped? h) => setState(() {
                        _huespedSeleccionadoId = h?.id;
                        _nombre.text = h?.nombre ?? '';
                        _dui.text = h?.dui ?? '';
                        _telefono.text = h?.telefono ?? '';
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
                      }),
                    ),
                    if (_tipo == TipoCuarto.familiar) ...[
                      const SizedBox(height: 14),
                      const Text('Cantidad de camas'),
                      const SizedBox(height: 8),
                      SelectorOpciones<int>(
                        opciones: const [2, 3, 4],
                        seleccionada: _camas,
                        etiqueta: (cantidad) => '$cantidad camas',
                        icono: (_) => Icons.bed_outlined,
                        alCambiar: (cantidad) => setState(() {
                          _camas = cantidad;
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SelectorOpciones<TipoTarifa>(
                      opciones: TipoTarifa.values,
                      seleccionada: _tarifa,
                      etiqueta: (tarifa) => tarifa.etiqueta,
                      icono: (tarifa) => tarifa.icono,
                      detalle: (tarifa) => formatearDinero(
                        tarifasEjemplo
                            .firstWhere((t) => t.tipo == tarifa)
                            .precioPara(_camasSeleccionadas),
                      ),
                      alCambiar: (tarifa) => setState(() {
                        _tarifa = tarifa;
                        _cantidad = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    ContadorCantidad(
                      etiqueta: _tarifa == TipoTarifa.porHora
                          ? 'Horas de estadía'
                          : 'Noches de estadía',
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
                        '$_cantidad ${_tarifa.unidad(_cantidad)}',
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
                      '${formatearDinero(_precioUnitario)} × $_cantidad ${_tarifa.unidad(_cantidad)}',
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
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available),
                label: Text(_guardando ? 'Guardando…' : 'Crear reserva'),
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
