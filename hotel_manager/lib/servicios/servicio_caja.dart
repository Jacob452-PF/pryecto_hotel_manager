import 'package:flutter/foundation.dart';

import '../modelos/caja.dart';
import '../modelos/usuario.dart';
import 'api_client.dart';
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
      if (c.usuarioId == u.id &&
          c.abierta &&
          c.id.startsWith('api-shift-')) {
        return c;
      }
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

  Future<void> sincronizar() async {
    final usuario = ServicioSesion.instancia.usuario;
    if (usuario?.rol != RolUsuario.admin &&
        usuario?.rol != RolUsuario.recepcion) {
      return;
    }

    final shift = await ApiClient.instance.currentShift();
    if (shift != null) {
      final id = 'api-shift-${shift['id']}';
      final existente = _cajas.indexWhere((caja) => caja.id == id);
      final desgloseExistente = existente < 0
          ? null
          : _cajas[existente].desgloseApertura;
      _cajas.removeWhere(
        (caja) =>
            caja.id.startsWith('api-shift-') && caja.abierta && caja.id != id,
      );
      final caja = Caja(
        id: id,
        usuarioId: (shift['user_id'] ?? usuario!.id).toString(),
        aperturaAt: DateTime.parse(shift['opened_at'].toString()),
        montoApertura: double.parse(shift['opening_amount'].toString()),
        desgloseApertura: desgloseExistente ?? DesgloseEfectivo(
          montoNoDesglosado:
              double.parse(shift['opening_amount'].toString()),
        ),
      );
      if (existente < 0) {
        _cajas.add(caja);
      } else {
        _cajas[_cajas.indexWhere((item) => item.id == id)] = caja;
      }
    } else {
      _cajas.removeWhere(
        (caja) => caja.id.startsWith('api-shift-') && caja.abierta,
      );
    }
    await _guardar();
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
    final remoto = await ApiClient.instance.openShift(desglose.total);
    final cajaApi = Caja(
      id: 'api-shift-${remoto['id']}',
      usuarioId: (remoto['user_id'] ?? u.id).toString(),
      aperturaAt: DateTime.tryParse(remoto['opened_at']?.toString() ?? '') ?? now,
      montoApertura:
          double.tryParse(remoto['opening_amount']?.toString() ?? '') ??
          desglose.total,
      desgloseApertura: desglose,
    );
    _cajas.removeWhere((x) => x.id.startsWith('api-shift-') && x.abierta);
    _cajas.add(cajaApi);
    await _guardar();
    notifyListeners();
    return cajaApi;
  }

  double esperadoAlCerrar(double netoTurno) =>
      (((cajaActual?.montoApertura ?? 0) + netoTurno) * 100).round() / 100;
  Future<Caja> cerrar({
    required DesgloseEfectivo desglose,
    required double netoTurno,
    required bool confirmarDiferencia,
    DateTime? cierreAt,
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
    final response = await ApiClient.instance.closeShift(
      desglose.total,
      notes: notas,
    );
    final shift = response['shift'] is Map
        ? Map<String, dynamic>.from(response['shift'] as Map)
        : const <String, dynamic>{};
    final diferenciaApi =
        double.tryParse(shift['difference']?.toString() ?? '') ?? diferencia;
    final cerrada = c.cerrar(
      fecha: cierreAt ?? DateTime.now(),
      desglose: desglose,
      diferencia: diferenciaApi,
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
