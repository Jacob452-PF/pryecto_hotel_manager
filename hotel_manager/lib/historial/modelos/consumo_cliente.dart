import '../../modelos/factura.dart';
import 'turno_caja.dart';
import '../../modelos/abono.dart';

/// Una línea de consumo (habitación, servicio o producto cobrado a un cliente).
class LineaConsumo {
  final String nombre;
  final double precio;
  final int cantidad;

  /// Sirve para armar "Detalle de ventas" en el cierre de caja.
  final TipoVenta tipo;

  const LineaConsumo(
    this.nombre,
    this.precio, [
    this.cantidad = 1,
    this.tipo = TipoVenta.productos,
  ]);

  double get importe => precio * cantidad;
}

/// Todo lo que consumió un cliente durante el turno.
class ConsumoCliente {
  /// Identifica la cuenta del cliente (habitación + nombre).
  final String id;
  final String cliente;

  /// Etiqueta que se muestra a la derecha, por ejemplo "#101".
  final String codigo;

  /// Lo cobrado al registrar al cliente: estadía y productos iniciales.
  final List<LineaConsumo> lineasIniciales;

  /// Productos o servicios que se le añadieron DESPUÉS (por ejemplo desde la tienda).
  final List<LineaConsumo> lineasAnadidas;

  /// Factura completa del registro del huésped: DUI, teléfono, habitación,
  /// tarifa, etc. Es null en los datos de ejemplo.
  final Factura? factura;

  /// Usuario que tenía la sesión abierta cuando se registró al cliente.
  final String registradoPor;

  /// ¿El cliente ya canceló (pagó) su cuenta?
  final bool pagado;
  final DateTime? pagadoEn;

  /// Cómo pagó: Efectivo, Tarjeta o Transferencia (vacío si no se indicó).
  final String metodoPago;
  final double montoAbonado;
  final List<Abono> abonos;

  /// [lineas] son las líneas iniciales (las del registro).
  const ConsumoCliente({
    this.id = '',
    required this.cliente,
    required this.codigo,
    required List<LineaConsumo> lineas,
    this.lineasAnadidas = const [],
    this.factura,
    this.registradoPor = '',
    this.pagado = true,
    this.pagadoEn,
    this.metodoPago = '',
    this.montoAbonado = 0,
    this.abonos = const [],
  }) : lineasIniciales = lineas;

  /// Todas las líneas: iniciales + añadidas después.
  List<LineaConsumo> get lineas => [...lineasIniciales, ...lineasAnadidas];

  int get articulos => lineas.fold(0, (s, l) => s + l.cantidad);
  double get total => lineas.fold(0.0, (s, l) => s + l.importe);
  double get saldo => (total - montoAbonado).clamp(0.0, total).toDouble();

  /// Lo que gastó al registrarse.
  double get totalInicial => lineasIniciales.fold(0.0, (s, l) => s + l.importe);

  /// Lo que gastó después, al añadir más productos.
  double get totalAnadido => lineasAnadidas.fold(0.0, (s, l) => s + l.importe);

  int get productosAnadidos => lineasAnadidas.fold(0, (s, l) => s + l.cantidad);
}
