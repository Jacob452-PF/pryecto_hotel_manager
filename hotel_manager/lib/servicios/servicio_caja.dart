import 'package:flutter/foundation.dart';

import '../modelos/caja.dart';
import '../modelos/usuario.dart';
import 'servicio_sesion.dart';
import 'servicio_storage.dart';

class ServicioCaja extends ChangeNotifier {
  ServicioCaja._();
  static final instancia = ServicioCaja._();
  final List<Caja> _cajas = [];
  List<Caja> get cajas => List.unmodifiable(_cajas);
  List<Caja> get cajasCerradas =>
      List.unmodifiable(_cajas.where((c) => !c.abierta));
  Caja? get cajaActual {
    final u = ServicioSesion.instancia.usuario;
    if (u == null) return null;
    for (final c in _cajas) {
      if (c.usuarioId == u.id && c.abierta) return c;
    }
    return null;
  }

  Future<void> cargar() async {
    final rows = await ServicioStorage.instancia.leerLista('hotel.cajas');
    _cajas
      ..clear()
      ..addAll(rows.map(Caja.fromJson));
    notifyListeners();
  }

  bool _puedeOperar() =>
      ServicioSesion.instancia.usuario?.rol == RolUsuario.recepcion ||
      ServicioSesion.instancia.usuario?.rol == RolUsuario.admin;
  Future<Caja> abrir(DesgloseEfectivo desglose) async {
    if (!_puedeOperar())
      throw StateError('Solo recepción o administración puede abrir caja.');
    if (cajaActual != null) throw StateError('Ya tienes una caja abierta.');
    final u = ServicioSesion.instancia.usuario!;
    final now = DateTime.now();
    final c = Caja(
      id: 'caja-${now.microsecondsSinceEpoch}',
      usuarioId: u.id,
      aperturaAt: now,
      montoApertura: desglose.total,
      desgloseApertura: desglose,
    );
    _cajas.add(c);
    await _guardar();
    notifyListeners();
    return c;
  }

  double esperadoAlCerrar(double netoTurno) =>
      (((cajaActual?.montoApertura ?? 0) + netoTurno) * 100).round() / 100;
  Future<Caja> cerrar({
    required DesgloseEfectivo desglose,
    required double netoTurno,
    required bool confirmarDiferencia,
    String? notas,
  }) async {
    if (!_puedeOperar())
      throw StateError('Solo recepción o administración puede cerrar caja.');
    final c = cajaActual;
    if (c == null) throw StateError('No hay caja abierta para este usuario.');
    final diferencia =
        ((desglose.total - esperadoAlCerrar(netoTurno)) * 100).round() / 100;
    if (diferencia != 0 && !confirmarDiferencia)
      throw StateError('Confirma la diferencia antes de cerrar caja.');
    final cerrada = c.cerrar(
      fecha: DateTime.now(),
      desglose: desglose,
      diferencia: diferencia,
      confirmada: confirmarDiferencia,
      notas: notas,
    );
    _cajas[_cajas.indexWhere((x) => x.id == c.id)] = cerrada;
    await _guardar();
    notifyListeners();
    return cerrada;
  }

  Future<void> _guardar() => ServicioStorage.instancia.guardarLista(
    'hotel.cajas',
    _cajas.map((c) => c.toJson()).toList(),
  );
}
