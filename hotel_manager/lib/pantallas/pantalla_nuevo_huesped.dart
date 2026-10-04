import 'package:flutter/material.dart';
import '../datos/productos_ejemplo.dart';
import '../datos/tarifas_ejemplo.dart';
import '../modelos/factura.dart';
import '../modelos/habitacion.dart';
import '../modelos/producto.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import '../servicios/servicio_habitaciones.dart';
import '../tema/estilos_botones.dart';
import '../tema/estilos_texto.dart';
import '../utilidades/formato.dart';
import '../widgets/catalogo_rapido.dart';
import '../widgets/contador_cantidad.dart';
import '../widgets/formulario_huesped.dart';
import '../widgets/resumen_factura.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_seccion.dart';
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

  // Parte 4: selección de la reserva
  TipoTarifa _tarifa = TipoTarifa.porNoche;
  int _cantidad = 1; // horas o noches, según la tarifa
  TipoCuarto _cuarto = TipoCuarto.matrimonial;
  int _camas = 2; // solo se elige cuando el tipo de cuarto es familiar
  Habitacion? _habitacionSeleccionada;

  // Parte 3 y 5: productos agregados a la factura
  final List<Producto> _productosAgregados = [];

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDui.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  /// Matrimonial e individual tienen 1 cama; la familiar usa la elegida (2, 3 o 4).
  int get _camasSeleccionadas => _cuarto == TipoCuarto.familiar ? _camas : 1;

  /// El precio por hora o por noche depende de la cantidad de camas.
  double get _precioUnitario => tarifasEjemplo
      .firstWhere((t) => t.tipo == _tarifa)
      .precioPara(_camasSeleccionadas);

  double get _montoEstadia => _precioUnitario * _cantidad;

  double get _total =>
      _montoEstadia + _productosAgregados.fold(0.0, (suma, p) => suma + p.precio);

  /// Habitaciones libres que cumplen lo elegido: el tipo de cuarto y,
  /// si es familiar, la cantidad de camas.
  List<Habitacion> get _habitacionesDisponibles => ServicioHabitaciones
      .instancia.habitaciones
      .where((h) =>
          h.estado == EstadoHabitacion.disponible &&
          h.tipoCuarto == _cuarto &&
          (_cuarto != TipoCuarto.familiar || h.camas == _camas))
      .toList();

  /// Si la habitación elegida ya no cumple los filtros, se quita la selección.
  void _revisarSeleccion() {
    if (_habitacionSeleccionada != null &&
        !_habitacionesDisponibles.contains(_habitacionSeleccionada)) {
      _habitacionSeleccionada = null;
    }
  }

  String _textoCamas(int n) => '$n ${n == 1 ? 'cama' : 'camas'}';

  void _confirmar() {
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

    final factura = Factura(
      fecha: DateTime.now(),
      huesped: _controladorNombre.text.trim(),
      dui: _controladorDui.text,
      telefono: _controladorTelefono.text,
      habitacion: habitacionElegida,
      tarifa: _tarifa,
      cantidad: _cantidad,
      precioUnitario: _precioUnitario,
      productos: List.of(_productosAgregados),
    );

    // La habitación pasa a ocupada con el nombre del huésped.
    ServicioHabitaciones.instancia.ocupar(habitacionElegida.numero, factura.huesped);

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
        '$_cantidad ${_tarifa.unidad(_cantidad)} × ${formatearDinero(_precioUnitario)}',
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
      hijo: FormularioHuesped(
        claveFormulario: _claveFormulario,
        controladorNombre: _controladorNombre,
        controladorDui: _controladorDui,
        controladorTelefono: _controladorTelefono,
      ),
    );

    final catalogo = TarjetaSeccion(
      titulo: 'Catálogo rápido',
      icono: Icons.storefront,
      hijo: CatalogoRapido(
        productos: productosEjemplo,
        alAgregar: (producto) => setState(() => _productosAgregados.add(producto)),
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
                      SelectorOpciones<TipoTarifa>(
                        opciones: TipoTarifa.values,
                        seleccionada: _tarifa,
                        etiqueta: (t) => t.etiqueta,
                        icono: (t) => t.icono,
                        // Precio según las camas elegidas
                        detalle: (t) => formatearDinero(
                          tarifasEjemplo
                              .firstWhere((x) => x.tipo == t)
                              .precioPara(_camasSeleccionadas),
                        ),
                        alCambiar: (t) => setState(() {
                          _tarifa = t;
                          _cantidad = 1;
                        }),
                      ),
                      const SizedBox(height: 16),
                      ContadorCantidad(
                        etiqueta: _tarifa == TipoTarifa.porHora ? 'Horas' : 'Noches',
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
                      _revisarSeleccion();
                    }),
                  ),
                ),
                // Las camas solo se eligen cuando el tipo es familiar (2, 3 o 4)
                if (_cuarto == TipoCuarto.familiar) ...[
                  const SizedBox(height: 16),
                  TarjetaSeccion(
                    titulo: 'Capacidad (camas)',
                    icono: Icons.bed,
                    hijo: SelectorOpciones<int>(
                      opciones: const [2, 3, 4],
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
                        onPressed: _confirmar,
                        child: const Text('Confirmar'),
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