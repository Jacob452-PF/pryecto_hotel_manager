import 'package:flutter/material.dart';
import '../datos/productos_ejemplo.dart';
import '../datos/tarifas_ejemplo.dart';
import '../modelos/producto.dart';
import '../modelos/tarifa.dart';
import '../modelos/tipo_cuarto.dart';
import '../tema/estilos_botones.dart';
import '../utilidades/formato.dart';
import '../widgets/catalogo_rapido.dart';
import '../widgets/contador_cantidad.dart';
import '../widgets/formulario_huesped.dart';
import '../widgets/resumen_factura.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_seccion.dart';

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
  TipoCuarto _cuarto = TipoCuarto.matrimonial;
  int _camas = 1;
  int _cantidad = 1; // horas o noches, según la tarifa

  // Parte 3 y 5: productos agregados a la factura
  final List<Producto> _productosAgregados = [];

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDui.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  double get _precioUnitario =>
      tarifasEjemplo.firstWhere((t) => t.tipo == _tarifa).precioUnitario;

  double get _montoEstadia => _precioUnitario * _cantidad;

  double get _total =>
      _montoEstadia + _productosAgregados.fold(0.0, (suma, p) => suma + p.precio);

  void _confirmar() {
    if (!_claveFormulario.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los datos del huésped')),
      );
      return;
    }

    // TODO: guardar la reserva (huésped, tarifa, cuarto, camas, productos, total).

    final mensajero = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensajero.showSnackBar(const SnackBar(content: Text('Reserva confirmada')));
  }

  @override
  Widget build(BuildContext context) {
    final lineasFactura = <LineaFactura>[
      LineaFactura(
        'Estadía: $_cantidad ${_tarifa.unidad(_cantidad)} × ${formatearDinero(_precioUnitario)}',
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

                // Parte 4: tarifa, tipo de cuarto y camas
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
                        detalle: (t) => formatearDinero(
                          tarifasEjemplo.firstWhere((x) => x.tipo == t).precioUnitario,
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
                    alCambiar: (c) => setState(() => _cuarto = c),
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaSeccion(
                  titulo: 'Capacidad (camas)',
                  icono: Icons.bed,
                  hijo: SelectorOpciones<int>(
                    opciones: const [1, 2, 3, 4],
                    seleccionada: _camas,
                    etiqueta: (n) => '$n ${n == 1 ? 'cama' : 'camas'}',
                    icono: (_) => Icons.bed,
                    alCambiar: (n) => setState(() => _camas = n),
                  ),
                ),
                const SizedBox(height: 16),

                // Parte 5: factura y botones
                TarjetaSeccion(
                  titulo: 'Factura',
                  icono: Icons.receipt_long,
                  hijo: ResumenFactura(
                    detalle:
                        '${_cuarto.etiqueta} · $_camas ${_camas == 1 ? 'cama' : 'camas'}',
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