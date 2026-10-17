import 'package:flutter/foundation.dart';

import '../datos/cajas_mock.dart';
import '../datos/turno_mock.dart';
import '../modelos/caja_cierre.dart';
import '../modelos/turno_caja.dart';

/// Guarda el historial de cierres de caja y el turno actual.
/// Vive en memoria; cuando haya base de datos, solo se cambia este archivo.
class ServicioHistorial extends ChangeNotifier {
  ServicioHistorial._();

  static final ServicioHistorial instancia = ServicioHistorial._();

  final List<CajaCierre> _cajas = crearCajasMock(DateTime.now());

  /// Turno que se va a cerrar (datos de ejemplo por ahora).
  final TurnoCaja turnoActual = crearTurnoMock();

  /// Cierres ordenados del más reciente al más antiguo.
  List<CajaCierre> get cajas {
    final lista = List.of(_cajas);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  /// Cierra el turno actual: agrega una caja nueva al historial.
  CajaCierre registrarCierre() {
    var mayor = 0;
    for (final c in _cajas) {
      final n = int.tryParse(c.numero) ?? 0;
      if (n > mayor) mayor = n;
    }
    final caja = CajaCierre(
      numero: (mayor + 1).toString().padLeft(3, '0'),
      fecha: DateTime.now(),
      cajero: turnoActual.usuario,
      totalRegistrado: turnoActual.totalEnCaja,
    );
    _cajas.add(caja);
    notifyListeners();
    return caja;
  }
}
