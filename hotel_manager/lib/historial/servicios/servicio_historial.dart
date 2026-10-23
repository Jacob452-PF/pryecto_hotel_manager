import 'package:flutter/foundation.dart';

import '../../inventario/servicios/servicio_inventario.dart';
import '../../modelos/habitacion.dart';
import '../../servicios/servicio_habitaciones.dart';
import '../datos/cajas_mock.dart';
//import '../datos/gastos_mock.dart';
import '../modelos/caja_cierre.dart';
import '../modelos/consumo_cliente.dart';
import '../modelos/turno_caja.dart';
import '../utilidades/sesion_actual.dart';
import 'servicio_consumos.dart';

/// Guarda el historial de cierres de caja y arma el turno actual.
/// Vive en memoria; cuando haya base de datos, solo se cambia este archivo.
class ServicioHistorial extends ChangeNotifier {
  ServicioHistorial._() {
    // Si cambia el inventario (compras, stock), el cierre se actualiza solo.
    ServicioInventario.instancia.addListener(notifyListeners);
  }

  static final ServicioHistorial instancia = ServicioHistorial._();

  final List<CajaCierre> _cajas = crearCajasMock(DateTime.now());
  //final List<GastoTurno> _gastos = crearGastosMock();

  /// Cierres ordenados del más reciente al más antiguo.
  List<CajaCierre> get cajas {
    final lista = List.of(_cajas);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  //Turno que se va a cerrar: ventas y clientes salen de lo que se
  //registró desde el último cierre.
  TurnoCaja get turnoActual {
    final clientes = ServicioConsumos.instancia.clientes;
    final habitaciones = ServicioHabitaciones.instancia.habitaciones;
    return TurnoCaja(
      usuario: nombreUsuarioActual(),
      ventas: _ventasDe(clientes),
      gastos: const [],
      habitacionesOcupadas: habitaciones
          .where((h) => h.estado == EstadoHabitacion.ocupada)
          .length,
      habitacionesTotal: habitaciones.length,
      clientes: clientes,
      gastosInventario: [
        for (final c in ServicioInventario.instancia.comprasDelTurno)
          GastoInventarioTurno(
            c.producto,
            '${c.esNuevo ? 'Nuevo' : 'Reposición'} · '
            '${c.paquetes} '
            '${c.paquetes == 1 ? 'paquete' : 'paquetes'} '
            '(${c.cantidad} uds)',
            c.total,
          ),
      ],
    );
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
  CajaCierre registrarCierre() {
    final turno = turnoActual;
    var mayor = 0;
    for (final c in _cajas) {
      final n = int.tryParse(c.numero) ?? 0;
      if (n > mayor) mayor = n;
    }
    final caja = CajaCierre(
      numero: (mayor + 1).toString().padLeft(3, '0'),
      fecha: DateTime.now(),
      cajero: turno.usuario,
      clientes: turno.clientes,
      totalRegistrado: turno.totalEnCaja,
    );
    _cajas.add(caja);
    //_gastos.clear();
    ServicioInventario.instancia.cerrarCompras(caja.numero);
    ServicioConsumos.instancia.vaciar();
    notifyListeners();
    return caja;
  }
}
