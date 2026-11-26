import 'dart:async';

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
import '../servicios/servicio_estadias.dart';
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
  bool _registrarDatosHuesped = false;

  // Parte 4: selección de la reserva
  TipoTarifa _tarifa = TipoTarifa.porNoche;
  final List<TarifaRemota> _tarifas = [];
  TarifaRemota? _tarifaRemota;
  String? _errorTarifas;
  bool _cargandoTarifas = true;
  bool _actualizandoTarifas = false;
  Timer? _temporizadorTarifas;
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
      .map(
        (producto) =>
            Producto(producto.nombre, producto.precio, idApi: producto.id),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    ServicioInventario.instancia.addListener(_actualizarCatalogo);
    _cargarTarifas();
    _temporizadorTarifas = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _cargarTarifas(),
    );
  }

  Future<void> _cargarTarifas() async {
    if (_actualizandoTarifas) return;
    _actualizandoTarifas = true;
    final tarifaAnteriorId = _tarifaRemota?.id;
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
        _tarifaRemota =
            _tarifasCompatibles
                .where((tarifa) => tarifa.id == tarifaAnteriorId)
                .firstOrNull ??
            _tarifasCompatibles.firstOrNull;
        _tarifa = (_tarifaRemota?.horas ?? 24) <= 6
            ? TipoTarifa.porHora
            : TipoTarifa.porNoche;
        _cargandoTarifas = false;
        _errorTarifas = rates.isEmpty
            ? 'No hay tarifas activas en el servidor.'
            : null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _cargandoTarifas = false;
        _errorTarifas = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _actualizandoTarifas = false;
    }
  }

  void _actualizarCatalogo() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _temporizadorTarifas?.cancel();
    ServicioInventario.instancia.removeListener(_actualizarCatalogo);
    _controladorNombre.dispose();
    _controladorDui.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  /// Las comunes tienen una cama; las especiales admiten de una a cuatro.
  int get _camasSeleccionadas => _cuarto == TipoCuarto.comun ? 1 : _camas;

  /// El precio por hora o por noche depende de la cantidad de camas.
  List<TarifaRemota> get _tarifasCompatibles => _tarifas
      .where(
        (t) =>
            t.tipoHabitacion == _cuarto.valorApi &&
            t.camas == _camasSeleccionadas,
      )
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

<<<<<<< Updated upstream
    final hayDatosCliente =
        _controladorNombre.text.trim().isNotEmpty ||
        _controladorDui.text.trim().isNotEmpty ||
        _controladorTelefono.text.trim().isNotEmpty;
    final guardarCliente = _huespedSeleccionadoId != null || hayDatosCliente;
    if (guardarCliente && !_claveFormulario.currentState!.validate()) {
=======
    if (_registrarDatosHuesped &&
        _huespedSeleccionadoId == null &&
        !_claveFormulario.currentState!.validate()) {
>>>>>>> Stashed changes
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
      mensajero.showSnackBar(
        SnackBar(
          content: Text(_errorTarifas ?? 'Selecciona una tarifa del servidor.'),
        ),
      );
      return;
    }
    if (_total <= 0) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('El total de la estadía debe ser mayor que cero.'),
        ),
      );
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

<<<<<<< Updated upstream
    Huesped? huesped;
    if (guardarCliente) {
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
=======
    final roomId = int.tryParse(habitacionElegida.id);
    if (roomId == null) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('La habitación no tiene un ID válido del servidor.'),
        ),
      );
      return;
>>>>>>> Stashed changes
    }

<<<<<<< Updated upstream
    final roomId = int.tryParse(habitacionElegida.id);
    final guestId = huesped == null ? null : int.tryParse(huesped.id);
    if (roomId == null || (huesped != null && guestId == null)) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text(
            'La habitación o el huésped no tiene un ID válido del servidor.',
          ),
=======
    Huesped? huesped;
    if (_registrarDatosHuesped) {
      try {
        if (_huespedSeleccionadoId != null) {
          huesped = ServicioHuespedes.instancia.huespedes
              .where((h) => h.id == _huespedSeleccionadoId)
              .firstOrNull;
        } else {
          huesped = await ServicioHuespedes.instancia.obtenerOCrear(
            nombre: _controladorNombre.text,
            dui: _controladorDui.text,
            telefono: _controladorTelefono.text,
          );
        }
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
      if (huesped == null) {
        setState(() => _guardando = false);
        mensajero.showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró el huésped seleccionado en la base de datos.',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final guestId = huesped == null ? null : int.tryParse(huesped.id);
    if (huesped != null && guestId == null) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('El huésped no tiene un ID válido del servidor.'),
>>>>>>> Stashed changes
        ),
      );
      return;
    }
    final itemsPorProducto = <int, int>{};
    for (final producto in _productosAgregados) {
      final id = int.tryParse(producto.idApi ?? '');
      if (id == null) {
        setState(() => _guardando = false);
        mensajero.showSnackBar(
          const SnackBar(
            content: Text('Un producto no pertenece al catálogo del servidor.'),
          ),
        );
        return;
      }
      itemsPorProducto.update(
        id,
        (cantidad) => cantidad + 1,
        ifAbsent: () => 1,
      );
    }
    late double precioFactura;
    late int cantidadFactura;
    late DateTime fechaFactura;
    late int horasFactura;
    late List<Producto> productosFactura;
    try {
      final respuesta = await ApiClient.instance.createStay({
        'room_id': roomId,
        if (guestId != null) 'guest_id': guestId,
<<<<<<< Updated upstream
        if (huesped != null) 'guest_name': huesped.nombre,
        if (huesped != null) 'guest_document': huesped.dui,
=======
        if (huesped == null && _registrarDatosHuesped)
          'guest_name': _controladorNombre.text.trim(),
        if (huesped == null && _registrarDatosHuesped)
          'guest_document': _controladorDui.text.trim(),
>>>>>>> Stashed changes
        'rate_id': tarifaRemota.id,
        'rate_units': _cantidad,
        'payment_method': pago.metodo.name,
        if (itemsPorProducto.isNotEmpty)
          'items': [
            for (final entry in itemsPorProducto.entries)
              {'product_id': entry.key, 'quantity': entry.value},
          ],
      });
<<<<<<< Updated upstream
      await Future.wait([
        ServicioHabitaciones.instancia.sincronizar(),
        ServicioEstadias.instancia.sincronizar(),
      ]);
=======
      await ServicioHabitaciones.instancia.sincronizar();
      final stayApi = respuesta['stay'] is Map
          ? Map<String, dynamic>.from(respuesta['stay'] as Map)
          : const <String, dynamic>{};
      final rateApi = stayApi['rate'] is Map
          ? Map<String, dynamic>.from(stayApi['rate'] as Map)
          : const <String, dynamic>{};
      precioFactura =
          double.tryParse(rateApi['price']?.toString() ?? '') ??
          _precioUnitario;
      cantidadFactura =
          int.tryParse(stayApi['rate_units']?.toString() ?? '') ?? _cantidad;
      final saleApi = respuesta['sale'] is Map
          ? Map<String, dynamic>.from(respuesta['sale'] as Map)
          : const <String, dynamic>{};
      productosFactura = <Producto>[];
      final saleItems = saleApi['items'];
      if (saleItems is List) {
        for (final row in saleItems.whereType<Map>()) {
          final item = Map<String, dynamic>.from(row);
          final product = item['product'] is Map
              ? Map<String, dynamic>.from(item['product'] as Map)
              : const <String, dynamic>{};
          final quantity =
              int.tryParse(item['quantity']?.toString() ?? '') ?? 1;
          final price =
              double.tryParse(item['unit_price']?.toString() ?? '') ?? 0;
          for (var i = 0; i < quantity; i++) {
            productosFactura.add(
              Producto(product['name']?.toString() ?? 'Producto', price),
            );
          }
        }
      }
      if (productosFactura.isEmpty)
        productosFactura.addAll(_productosAgregados);
      fechaFactura =
          DateTime.tryParse(stayApi['check_in_at']?.toString() ?? '') ??
          fechaEntrada;
      horasFactura =
          int.tryParse(rateApi['hours']?.toString() ?? '') ??
          tarifaRemota.horas;
>>>>>>> Stashed changes
    } on Object catch (error) {
      if (mounted) {
        setState(() => _guardando = false);
        mensajero.showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    final factura = Factura(
<<<<<<< Updated upstream
      fecha: fechaEntrada,
=======
      fecha: fechaFactura,
>>>>>>> Stashed changes
      huesped: huesped?.nombre ?? 'Cliente sin registrar',
      dui: huesped?.dui ?? '',
      telefono: huesped?.telefono ?? '',
      habitacion: habitacionElegida,
      tarifa: horasFactura <= 6 ? TipoTarifa.porHora : TipoTarifa.porNoche,
      cantidad: cantidadFactura,
      precioUnitario: precioFactura,
      productos: productosFactura,
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

<<<<<<< Updated upstream
    final formulario = TarjetaSeccion(
      titulo: 'Datos del huésped (opcional)',
      icono: Icons.person_add,
      hijo: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Puedes dejar estos campos vacíos para registrar la estadía sin identificar al cliente. Si ingresas datos o eliges un huésped guardado, aparecerán en la habitación.',
            ),
          ),
          SelectorHuespedGuardado(
            seleccionadoId: _huespedSeleccionadoId,
            alCambiar: (Huesped? h) => setState(() {
              _huespedSeleccionadoId = h?.id;
              _controladorNombre.text = h?.nombre ?? '';
              _controladorDui.text = h?.dui ?? '';
              _controladorTelefono.text = h?.telefono ?? '';
=======
    final formulario = Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _registrarDatosHuesped,
            title: const Text('Guardar los datos del cliente'),
            subtitle: const Text(
              'Opcional para una venta directa de habitación.',
            ),
            secondary: const Icon(Icons.person_add_alt_1),
            onChanged: (value) => setState(() {
              _registrarDatosHuesped = value;
              if (!value) _claveFormulario.currentState?.reset();
>>>>>>> Stashed changes
            }),
          ),
          if (_registrarDatosHuesped)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
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
        title: const Text('Venta directa de habitación'),
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
                        Text(
                          _errorTarifas ??
                              'No hay tarifas para ${_cuarto.etiqueta.toLowerCase()} de $_camasSeleccionadas ${_camasSeleccionadas == 1 ? 'cama' : 'camas'}.',
                        )
                      else
                        DropdownButtonFormField<TarifaRemota>(
                          value: _tarifasCompatibles.contains(_tarifaRemota)
                              ? _tarifaRemota
                              : _tarifasCompatibles.first,
                          decoration: const InputDecoration(
                            labelText: 'Tarifa del servidor',
                          ),
                          items: [
                            for (final tarifa in _tarifasCompatibles)
                              DropdownMenuItem(
                                value: tarifa,
                                child: Text(
                                  '${tarifa.etiquetaDuracion} · ${formatearDinero(tarifa.precio)}',
                                ),
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
                        etiqueta:
                            'Bloques de ${_tarifaRemota?.horas ?? 0} horas',
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
                        _tarifaRemota = _tarifasCompatibles.firstOrNull;
                        _tarifa = (_tarifaRemota?.horas ?? 24) <= 6
                            ? TipoTarifa.porHora
                            : TipoTarifa.porNoche;
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
                        onPressed:
                            _guardando ||
                                _cargandoTarifas ||
                                _tarifaRemota == null
                            ? null
                            : _confirmar,
                        child: Text(
                          _guardando ? 'Registrando…' : 'Confirmar y cobrar',
                        ),
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
