import 'package:flutter/foundation.dart';

import '../../inventario/servicios/servicio_inventario.dart';
import '../../inventario/modelos/compra_inventario.dart';
import '../../modelos/habitacion.dart';
import '../../servicios/servicio_habitaciones.dart';
import '../../servicios/servicio_caja.dart';
import '../../servicios/servicio_sesion.dart';
import '../modelos/caja_cierre.dart';
import '../modelos/consumo_cliente.dart';
import '../modelos/turno_caja.dart';
import '../utilidades/sesion_actual.dart';
import 'servicio_consumos.dart';

class _ClienteTurnoServidor {
  final String id;
  final String cliente;
  final String codigo;
  final String registradoPor;
  final List<LineaConsumo> lineas = [];
  final Set<String> metodosPago = {};

  _ClienteTurnoServidor({
    required this.id,
    required this.cliente,
    required this.codigo,
    required this.registradoPor,
  });

  ConsumoCliente aConsumo() => ConsumoCliente(
    id: id,
    cliente: cliente,
    codigo: codigo,
    lineas: List.unmodifiable(lineas),
    registradoPor: registradoPor,
    pagado: true,
    metodoPago: metodosPago.join(', '),
  );
}

/// Guarda el historial de cierres de caja y arma el turno actual.
/// Vive en memoria; cuando haya base de datos, solo se cambia este archivo.
class ServicioHistorial extends ChangeNotifier {
  ServicioHistorial._() {
    // Si cambia el inventario (compras, stock), el cierre se actualiza solo.
    ServicioInventario.instancia.addListener(notifyListeners);
    ServicioCaja.instancia.addListener(notifyListeners);
  }

  static final ServicioHistorial instancia = ServicioHistorial._();

  /// No se muestran cierres de ejemplo como datos reales.
  final List<CajaCierre> _cajas = [];

  /// Gastos registrados a mano (cocina, limpieza...). Empieza vacío: cuando
  /// haya una pantalla para registrarlos, se llenará aquí.
  final List<GastoTurno> _gastos = [];

  /// Cierres ordenados del más reciente al más antiguo.
  List<CajaCierre> get cajas {
    final lista = List.of(_cajas);
    for (final c in ServicioCaja.instancia.cajasCerradas) {
      if (lista.any((x) => x.numero == c.id)) continue;
      final actual = ServicioSesion.instancia.usuario;
      final nombre = c.usuarioId == actual?.id ? actual?.nombre : c.usuarioId;
      lista.add(
        CajaCierre(
          numero: c.id,
          aperturaAt: c.aperturaAt,
          fecha: c.cierreAt!,
          cajero: nombre ?? c.usuarioId,
          totalRegistrado: c.montoCierre ?? 0,
        ),
      );
    }
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  /// Turno que se va a cerrar: ventas y clientes salen de lo que se
  /// registró desde el último cierre. Las estadías y ventas de caja se leen
  /// del servidor, incluso cuando el cliente no dejó datos personales.
  TurnoCaja get turnoActual {
    final clientes = _clientesDelTurno();
    final habitaciones = ServicioHabitaciones.instancia.habitaciones;
    return TurnoCaja(
      usuario: nombreUsuarioActual(),
      ventas: _ventasDe(clientes),
      gastos: List.unmodifiable(_gastos),
      habitacionesOcupadas: habitaciones
          .where((h) => h.estado == EstadoHabitacion.ocupada)
          .length,
      habitacionesTotal: habitaciones.length,
      clientes: clientes,
      gastosInventario: [
        for (final c in ServicioInventario.instancia.comprasDelTurno)
          GastoInventarioTurno(
            c.producto,
            '${switch (c.tipo) {
              TipoMovimientoCompra.compra => c.esNuevo ? 'Nuevo' : 'Reposición',
              TipoMovimientoCompra.devolucionCliente => 'Devolución de cliente',
              TipoMovimientoCompra.devolucionProveedor => 'Devolución a proveedor',
            }} · ${c.cantidad} ${c.cantidad == 1 ? 'unidad' : 'unidades'} × \$${c.costoUnitario.toStringAsFixed(2)}${c.editada ? ' · editado' : ''}',
            c.total,
            c.editada ? c.totalOriginal : null,
          ),
      ],
    );
  }

  List<ConsumoCliente> _clientesDelTurno() {
    final locales = ServicioConsumos.instancia.clientes;
    final agrupados = <String, _ClienteTurnoServidor>{};

    // Count stays independently of the guest registry and of whether the stay
    // produced a completed sale (for example, a complimentary stay).
    for (final estadia in ServicioCaja.instancia.estadiasServidor) {
      final estadiaId = estadia['id']?.toString();
      if (estadiaId == null || estadiaId.isEmpty) continue;
      final habitacion = estadia['room'] is Map
          ? Map<String, dynamic>.from(estadia['room'] as Map)
          : <String, dynamic>{};
      final numeroHabitacion = habitacion['number']?.toString();
      final huesped = estadia['guest_name']?.toString().trim();
      agrupados.putIfAbsent(
        'estadia:$estadiaId',
        () => _ClienteTurnoServidor(
          id: 'estadia:$estadiaId',
          cliente: huesped == null || huesped.isEmpty
              ? 'Cliente sin registro'
              : huesped,
          codigo: numeroHabitacion == null || numeroHabitacion.isEmpty
              ? 'Estadía #$estadiaId'
              : '#$numeroHabitacion',
          registradoPor: estadia['user'] is Map
              ? '${(estadia['user'] as Map)['name'] ?? ''}'
              : '',
        ),
      );
    }

    for (final venta in ServicioCaja.instancia.ventasServidor) {
      final ventaId = venta['id']?.toString();
      if (ventaId == null || ventaId.isEmpty) continue;

      final estadia = venta['stay'] is Map
          ? Map<String, dynamic>.from(venta['stay'] as Map)
          : <String, dynamic>{};
      final habitacion = estadia['room'] is Map
          ? Map<String, dynamic>.from(estadia['room'] as Map)
          : <String, dynamic>{};
      final estadiaId = estadia['id'] ?? venta['stay_id'];
      final numeroHabitacion = habitacion['number']?.toString();
      final llave = estadiaId == null ? 'venta:$ventaId' : 'estadia:$estadiaId';
      final huesped = estadia['guest_name']?.toString().trim();
      final cuenta = agrupados.putIfAbsent(
        llave,
        () => _ClienteTurnoServidor(
          id: llave,
          cliente: huesped == null || huesped.isEmpty
              ? (estadiaId == null ? 'Cliente de tienda' : 'Cliente sin registro')
              : huesped,
          codigo: numeroHabitacion == null || numeroHabitacion.isEmpty
              ? 'Venta #$ventaId'
              : '#$numeroHabitacion',
          registradoPor: venta['user'] is Map
              ? '${(venta['user'] as Map)['name'] ?? ''}'
              : '',
        ),
      );

      final montoHabitacion =
          double.tryParse('${venta['room_amount'] ?? 0}') ?? 0;
      if (montoHabitacion > 0) {
        cuenta.lineas.add(
          LineaConsumo(
            numeroHabitacion == null
                ? 'Habitación'
                : 'Habitación $numeroHabitacion',
            montoHabitacion,
            1,
            TipoVenta.habitaciones,
          ),
        );
      }

      final items = venta['items'];
      if (items is List) {
        for (final rawItem in items.whereType<Map>()) {
          final cantidad = int.tryParse('${rawItem['quantity']}') ?? 1;
          final subtotal = double.tryParse('${rawItem['subtotal']}') ??
              ((double.tryParse('${rawItem['unit_price']}') ?? 0) * cantidad);
          final producto = rawItem['product'] is Map
              ? (rawItem['product'] as Map)['name']?.toString()
              : null;
          cuenta.lineas.add(
            LineaConsumo(
              producto == null || producto.isEmpty ? 'Producto' : producto,
              cantidad > 0 ? subtotal / cantidad : subtotal,
              cantidad,
              TipoVenta.productos,
            ),
          );
        }
      }

      final metodo = venta['payment_method']?.toString().trim();
      if (metodo != null && metodo.isNotEmpty) cuenta.metodosPago.add(metodo);
    }

    final firmasLocales = locales
        .map((cliente) => '${cliente.codigo}|${cliente.cliente.trim().toLowerCase()}')
        .toSet();
    final clientesServidor = agrupados.values
        .map((cuenta) => cuenta.aConsumo())
        .where(
          (cliente) => !firmasLocales.contains(
            '${cliente.codigo}|${cliente.cliente.trim().toLowerCase()}',
          ),
        );
    return [...locales, ...clientesServidor];
  }

  /// Agrupa las líneas de todos los clientes por tipo de venta.
  List<VentaTurno> _ventasDe(List<ConsumoCliente> clientes) {
    final ventas = <VentaTurno>[];
    for (final tipo in TipoVenta.values) {
      var cantidad = 0;
      var monto = 0.0;
      for (final c in clientes) {
        for (final l in c.lineas) {
          if (l.tipo == tipo) {
            cantidad += l.cantidad;
            monto += l.importe;
          }
        }
      }
      ventas.add(VentaTurno(tipo, cantidad, monto));
    }
    return ventas;
  }

  /// Cierra el turno: guarda la caja con el detalle de clientes y deja
  /// el turno en cero para el siguiente.
  CajaCierre registrarCierre({
    String? numero,
    double? totalRegistrado,
    DateTime? aperturaAt,
    DateTime? cierreAt,
  }) {
    final turno = turnoActual;
    var mayor = 0;
    for (final c in _cajas) {
      final n = int.tryParse(c.numero) ?? 0;
      if (n > mayor) mayor = n;
    }
    final caja = CajaCierre(
      numero: numero ?? (mayor + 1).toString().padLeft(3, '0'),
      aperturaAt: aperturaAt,
      fecha: cierreAt ?? DateTime.now(),
      cajero: turno.usuario,
      clientes: turno.clientes,
      totalRegistrado: totalRegistrado ?? turno.totalEnCaja,
    );
    _cajas.add(caja);
    _gastos.clear();
    ServicioInventario.instancia.cerrarCompras(caja.numero);
    ServicioConsumos.instancia.vaciar();
    notifyListeners();
    return caja;
  }
}
