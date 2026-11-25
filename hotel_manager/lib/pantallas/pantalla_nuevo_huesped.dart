import 'package:flutter/material.dart';

import '../inventario/servicios/servicio_inventario.dart';
import '../modelos/factura.dart';
import '../modelos/habitacion.dart';
import '../modelos/huesped.dart';
import '../modelos/producto.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/api_client.dart';
import '../widgets/dialogo_cobro.dart';
import '../tema/estilos_botones.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';
import '../widgets/catalogo_rapido.dart';
import '../widgets/contador_cantidad.dart';
import '../widgets/formulario_huesped.dart';
import '../widgets/resumen_factura.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_seccion.dart';
import '../widgets/selector_huesped_guardado.dart';
import 'pantalla_factura.dart';

class PantallaNuevoHuesped extends StatefulWidget {
  const PantallaNuevoHuesped({super.key});

  @override
  State<PantallaNuevoHuesped> createState() => _EstadoPantallaNuevoHuesped();
}

class _EstadoPantallaNuevoHuesped extends State<PantallaNuevoHuesped> {
  // Parte 2: datos del huésped
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorDui = TextEditingController();
  final _controladorTelefono = TextEditingController();
  String? _huespedSeleccionadoId;

  // Parte 4: selección de la reserva
  TipoTarifa _tarifa = TipoTarifa.porNoche;
  final List<TarifaRemota> _tarifas = [];
  TarifaRemota? _tarifaRemota;
  String? _errorTarifas;
  bool _cargandoTarifas = true;
  bool _guardando = false;
  int _cantidad = 1; // horas o noches, según la tarifa
  TipoCuarto _cuarto = TipoCuarto.comun;
  int _camas = 1; // las habitaciones especiales permiten elegir capacidad
  Habitacion? _habitacionSeleccionada;

  // Parte 3 y 5: productos agregados a la factura
  final List<Producto> _productosAgregados = [];

  List<Producto> get _productosCatalogo => ServicioInventario
      .instancia
      .productos
      .where((producto) => producto.stock > 0)
      .map((producto) => Producto(producto.nombre, producto.precio, idApi: producto.id))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    ServicioInventario.instancia.addListener(_actualizarCatalogo);
    _cargarTarifas();
  }

  Future<void> _cargarTarifas() async {
    try {
      final response = await ApiClient.instance.rates();
      final rates = ApiClient.instance.listFromResponse(response)
          .map((row) => TarifaRemota.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _tarifas
          ..clear()
          ..addAll(rates);
        _tarifaRemota = _tarifasCompatibles.firstOrNull;
        _tarifa = (_tarifaRemota?.horas ?? 24) <= 6
            ? TipoTarifa.porHora
            : TipoTarifa.porNoche;
        _cargandoTarifas = false;
        _errorTarifas = rates.isEmpty ? 'No hay tarifas activas en el servidor.' : null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _cargandoTarifas = false;
        _errorTarifas = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _actualizarCatalogo() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ServicioInventario.instancia.removeListener(_actualizarCatalogo);
    _controladorNombre.dispose();
    _controladorDui.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  /// Las comunes tienen una cama; las especiales admiten de una a cuatro.
  int get _camasSeleccionadas =>
      _cuarto == TipoCuarto.comun ? 1 : _camas;

  /// El precio por hora o por noche depende de la cantidad de camas.
  List<TarifaRemota> get _tarifasCompatibles => _tarifas
      .where((t) => t.tipoHabitacion == null || t.tipoHabitacion == _cuarto.valorApi)
      .toList();

  double get _precioUnitario => _tarifaRemota?.precio ?? 0;

  double get _montoEstadia => _precioUnitario * _cantidad;

  double get _total =>
      _montoEstadia +
      _productosAgregados.fold(0.0, (suma, p) => suma + p.precio);

  /// Habitaciones libres que cumplen lo elegido: el tipo de cuarto y,
  /// si es especial, la cantidad de camas.
  List<Habitacion> get _habitacionesDisponibles => ServicioHabitaciones
      .instancia
      .habitaciones
      .where(
        (h) =>
            h.estado == EstadoHabitacion.disponible &&
            h.tipoCuarto == _cuarto &&
            (_cuarto != TipoCuarto.especial || h.camas == _camas),
      )
      .toList();

  /// Si la habitación elegida ya no cumple los filtros, se quita la selección.
  void _revisarSeleccion() {
    if (_habitacionSeleccionada != null &&
        !_habitacionesDisponibles.contains(_habitacionSeleccionada)) {
      _habitacionSeleccionada = null;
    }
  }

  String _textoCamas(int n) => '$n ${n == 1 ? 'cama' : 'camas'}';

  Future<void> _confirmar() async {
    if (_guardando) return;
    final mensajero = ScaffoldMessenger.of(context);

    if (!_claveFormulario.currentState!.validate()) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('Revisa los datos del huésped')),
      );
      return;
    }

    final habitacionElegida = _habitacionSeleccionada;
    if (habitacionElegida == null) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('Selecciona una habitación')),
      );
      return;
    }
    final tarifaRemota = _tarifaRemota;
    if (tarifaRemota == null || !_tarifasCompatibles.contains(tarifaRemota)) {
      mensajero.showSnackBar(SnackBar(content: Text(_errorTarifas ?? 'Selecciona una tarifa del servidor.')));
      return;
    }
    if (_total <= 0) {
      mensajero.showSnackBar(const SnackBar(content: Text('El total de la estadía debe ser mayor que cero.')));
      return;
    }

    final fechaEntrada = DateTime.now();
    final duracion = Duration(hours: tarifaRemota.horas * _cantidad);
    if (!ServicioReservas.instancia.validarEstadiaContraReservas(
      habitacion: habitacionElegida.numero,
      inicio: fechaEntrada,
      fin: fechaEntrada.add(duracion),
    )) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text(
            'La estadía no deja el margen necesario antes de una reserva.',
          ),
        ),
      );
      return;
    }

    final pago = await mostrarDialogoCobro(context, saldo: _total);
    if (pago == null || !mounted) return;
    setState(() => _guardando = true);

    late final Huesped huesped;
    try {
      huesped = await ServicioHuespedes.instancia.obtenerOCrear(
        nombre: _controladorNombre.text,
        dui: _controladorDui.text,
        telefono: _controladorTelefono.text,
      );
    } on Object catch (e) {
      mensajero.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el huésped en el servidor: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
      if (mounted) setState(() => _guardando = false);
      return;
    }
    if (!mounted) return;

    final roomId = int.tryParse(habitacionElegida.id);
    final guestId = int.tryParse(huesped.id);
    if (roomId == null || guestId == null) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(const SnackBar(content: Text('La habitación o el huésped no tiene un ID válido del servidor.')));
      return;
    }
    final itemsPorProducto = <int, int>{};
    for (final producto in _productosAgregados) {
      final id = int.tryParse(producto.idApi ?? '');
      if (id == null) {
        setState(() => _guardando = false);
        mensajero.showSnackBar(const SnackBar(content: Text('Un producto no pertenece al catálogo del servidor.')));
        return;
      }
      itemsPorProducto.update(id, (cantidad) => cantidad + 1, ifAbsent: () => 1);
    }
    try {
      await ApiClient.instance.createStay({
        'room_id': roomId,
        'guest_id': guestId,
        'rate_id': tarifaRemota.id,
        'rate_units': _cantidad,
        'payment_method': pago.metodo.name,
        if (itemsPorProducto.isNotEmpty)
          'items': [
            for (final entry in itemsPorProducto.entries)
              {'product_id': entry.key, 'quantity': entry.value},
          ],
      });
      await ServicioHabitaciones.instancia.sincronizar();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _guardando = false);
        mensajero.showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
      return;
    }
    if (!mounted) return;

    final factura = Factura(
      fecha: fechaEntrada,
      huesped: huesped.nombre,
      dui: huesped.dui,
      telefono: huesped.telefono,
      habitacion: habitacionElegida,
      tarifa: _tarifa,
      cantidad: _cantidad,
      precioUnitario: _precioUnitario,
      productos: List.of(_productosAgregados),
    );

    // Se reemplaza esta pantalla por la factura inicial.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PantallaFactura(factura: factura)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _habitacionesDisponibles;
    final habitacion = _habitacionSeleccionada;

    final lineasFactura = <LineaFactura>[
      LineaFactura(
        'Estadía (${_textoCamas(_camasSeleccionadas)}): '
        '$_cantidad bloque(s) de ${_tarifaRemota?.horas ?? 0} h × ${formatearDinero(_precioUnitario)}',
        _montoEstadia,
      ),
      for (var i = 0; i < _productosAgregados.length; i++)
        LineaFactura(
          _productosAgregados[i].nombre,
          _productosAgregados[i].precio,
          alQuitar: () => setState(() => _productosAgregados.removeAt(i)),
        ),
    ];

    final formulario = TarjetaSeccion(
      titulo: 'Datos del huésped',
      icono: Icons.person_add,
      hijo: Column(
        children: [
          SelectorHuespedGuardado(
            seleccionadoId: _huespedSeleccionadoId,
            alCambiar: (Huesped? h) => setState(() {
              _huespedSeleccionadoId = h?.id;
              _controladorNombre.text = h?.nombre ?? '';
              _controladorDui.text = h?.dui ?? '';
              _controladorTelefono.text = h?.telefono ?? '';
            }),
          ),
          FormularioHuesped(
            claveFormulario: _claveFormulario,
            controladorNombre: _controladorNombre,
            controladorDui: _controladorDui,
            controladorTelefono: _controladorTelefono,
          ),
        ],
      ),
    );

    final catalogo = TarjetaSeccion(
      titulo: 'Catálogo rápido',
      icono: Icons.storefront,
      hijo: CatalogoRapido(
        productos: _productosCatalogo,
        alAgregar: (producto) =>
            setState(() => _productosAgregados.add(producto)),
      ),
    );

    return Scaffold(
      // Parte 1: botón de regresar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nuevo huésped'),
      ),
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final pantallaAncha = restricciones.maxWidth >= 700;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Partes 2 y 3: formulario a la izquierda, catálogo a la derecha
                // (en pantallas angostas se apilan uno sobre otro)
                if (pantallaAncha)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: formulario),
                      const SizedBox(width: 16),
                      Expanded(child: catalogo),
                    ],
                  )
                else ...[
                  formulario,
                  const SizedBox(height: 16),
                  catalogo,
                ],
                const SizedBox(height: 16),

                // Parte 4: tarifa, tipo de cuarto, camas y habitaciones
                TarjetaSeccion(
                  titulo: 'Tarifa',
                  icono: Icons.payments,
                  hijo: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_cargandoTarifas)
                        const LinearProgressIndicator()
                      else if (_tarifasCompatibles.isEmpty)
                        Text(_errorTarifas ?? 'No hay tarifas para este tipo de habitación.')
                      else
                        DropdownButtonFormField<TarifaRemota>(
                          value: _tarifasCompatibles.contains(_tarifaRemota)
                              ? _tarifaRemota
                              : _tarifasCompatibles.first,
                          decoration: const InputDecoration(labelText: 'Tarifa del servidor'),
                          items: [
                            for (final tarifa in _tarifasCompatibles)
                              DropdownMenuItem(
                                value: tarifa,
                                child: Text('${tarifa.nombre} · ${tarifa.horas} h · ${formatearDinero(tarifa.precio)}'),
                              ),
                          ],
                          onChanged: (tarifa) => setState(() {
                            _tarifaRemota = tarifa;
                            _tarifa = (tarifa?.horas ?? 24) <= 6
                                ? TipoTarifa.porHora
                                : TipoTarifa.porNoche;
                            _cantidad = 1;
                          }),
                        ),
                      const SizedBox(height: 16),
                      ContadorCantidad(
                        etiqueta: 'Bloques de ${_tarifaRemota?.horas ?? 0} horas',
                        valor: _cantidad,
                        alCambiar: (n) => setState(() => _cantidad = n),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Tipo de habitación',
                  icono: Icons.meeting_room,
                  hijo: SelectorOpciones<TipoCuarto>(
                    opciones: TipoCuarto.values,
                    seleccionada: _cuarto,
                    etiqueta: (c) => c.etiqueta,
                    icono: (c) => c.icono,
                    alCambiar: (c) => setState(() {
                      _cuarto = c;
                      _tarifaRemota = _tarifasCompatibles.firstOrNull;
                      _tarifa = (_tarifaRemota?.horas ?? 24) <= 6
                          ? TipoTarifa.porHora
                          : TipoTarifa.porNoche;
                      _revisarSeleccion();
                    }),
                  ),
                ),
                // Las habitaciones especiales permiten elegir de una a cuatro camas.
                if (_cuarto == TipoCuarto.especial) ...[
                  const SizedBox(height: 16),
                  TarjetaSeccion(
                    titulo: 'Capacidad (camas)',
                    icono: Icons.bed,
                    hijo: SelectorOpciones<int>(
                      opciones: const [1, 2, 3, 4],
                      seleccionada: _camas,
                      etiqueta: (n) => '$n camas',
                      icono: (_) => Icons.bed,
                      alCambiar: (n) => setState(() {
                        _camas = n;
                        _revisarSeleccion();
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Habitaciones disponibles',
                  icono: Icons.door_front_door,
                  hijo: disponibles.isEmpty
                      ? const Text(
                          'No hay habitaciones disponibles con estas características',
                          style: EstilosTexto.textoVacio,
                        )
                      : SelectorOpciones<Habitacion>(
                          opciones: disponibles,
                          seleccionada: _habitacionSeleccionada,
                          etiqueta: (h) => 'Hab. ${h.numero}',
                          icono: (h) => h.tipoCuarto.icono,
                          detalle: (h) => 'Piso ${h.piso}',
                          alCambiar: (h) =>
                              setState(() => _habitacionSeleccionada = h),
                        ),
                ),
                const SizedBox(height: 16),

                // Parte 5: factura y botones
                TarjetaSeccion(
                  titulo: 'Factura',
                  icono: Icons.receipt_long,
                  hijo: ResumenFactura(
                    detalle: habitacion == null
                        ? 'Sin habitación seleccionada'
                        : 'Habitación ${habitacion.numero} · ${habitacion.tipoCuarto.etiqueta} · ${_textoCamas(habitacion.camas)}',
                    lineas: lineasFactura,
                    total: _total,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: EstilosBotones.cancelar,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _guardando || _cargandoTarifas || _tarifaRemota == null
                            ? null
                            : _confirmar,
                        child: Text(_guardando ? 'Registrando…' : 'Confirmar y cobrar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
