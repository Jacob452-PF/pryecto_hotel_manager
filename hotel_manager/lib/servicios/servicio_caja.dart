import 'package:flutter/foundation.dart';

import '../modelos/caja.dart';
import '../modelos/usuario.dart';
import 'api_client.dart';
import 'servicio_sesion.dart';
import 'servicio_storage.dart';
import 'servicio_reservas.dart';
import 'servicio_notificaciones.dart';

class ServicioCaja extends ChangeNotifier {
  ServicioCaja._();
  static final instancia = ServicioCaja._();
  final List<Caja> _cajas = [];
  bool _consultada = false;
  bool get consultada => _consultada;
  bool _sincronizando = false;
  bool get sincronizando => _sincronizando;
  Future<void>? _futuraSincronizacion;
  Map<String, dynamic>? _resumenServidor;
  List<Map<String, dynamic>> _ventasServidor = const [];
  List<Map<String, dynamic>> _gastosServidor = const [];
  List<Map<String, dynamic>> _comprasServidor = const [];
  Map<String, dynamic>? _datosTurnoServidor;
  Map<String, dynamic>? get datosTurnoServidor => _datosTurnoServidor == null
      ? null
      : Map.unmodifiable(_datosTurnoServidor!);
  Map<String, dynamic>? get resumenServidor =>
      _resumenServidor == null ? null : Map.unmodifiable(_resumenServidor!);
  List<Map<String, dynamic>> get ventasServidor =>
      List.unmodifiable(_ventasServidor);
  List<Map<String, dynamic>> get gastosServidor =>
      List.unmodifiable(_gastosServidor);
  List<Map<String, dynamic>> get comprasServidor =>
      List.unmodifiable(_comprasServidor);
  List<Caja> get cajas => List.unmodifiable(_cajas);
  List<Caja> get cajasCerradas =>
      List.unmodifiable(_cajas.where((c) => !c.abierta));
  Caja? get cajaActual {
    final u = ServicioSesion.instancia.usuario;
    if (u == null) return null;
    for (final c in _cajas) {
      if (c.usuarioId == u.id && c.abierta && c.id.startsWith('api-shift-')) {
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

  Future<void> sincronizar() {
    final activa = _futuraSincronizacion;
    if (activa != null) return activa;
    final futura = _sincronizar();
    _futuraSincronizacion = futura;
    return futura.whenComplete(() {
      if (identical(_futuraSincronizacion, futura)) {
        _futuraSincronizacion = null;
      }
    });
  }

  Future<void> _sincronizar() async {
    _consultada = false;
    final usuario = ServicioSesion.instancia.usuario;
    if (usuario?.rol != RolUsuario.admin &&
        usuario?.rol != RolUsuario.recepcion) {
      return;
    }

    _sincronizando = true;
    try {
      final detalleTurno = await ApiClient.instance.currentShiftDetails();
      final shiftRaw = detalleTurno?['shift'];
      final shift = shiftRaw is Map
          ? Map<String, dynamic>.from(shiftRaw)
          : detalleTurno;
      _datosTurnoServidor = shift;
      _resumenServidor = detalleTurno?['summary'] is Map
          ? Map<String, dynamic>.from(detalleTurno!['summary'] as Map)
          : null;
      _ventasServidor = _mapasDe(detalleTurno?['sales']);
      _gastosServidor = _mapasDe(detalleTurno?['expenses']);
      _comprasServidor = _mapasDe(detalleTurno?['purchases']);
      _consultada = true;
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
          desgloseApertura:
              desgloseExistente ??
              (shift['opening_breakdown'] is Map
                  ? DesgloseEfectivo.fromJson(
                      Map<String, dynamic>.from(
                        shift['opening_breakdown'] as Map,
                      ),
                    )
                  : DesgloseEfectivo(
                      montoNoDesglosado: double.parse(
                        shift['opening_amount'].toString(),
                      ),
                    )),
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
    } finally {
      _sincronizando = false;
    }
  }

  List<Map<String, dynamic>> _mapasDe(dynamic valor) => valor is List
      ? valor.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  bool _puedeOperar() =>
      ServicioSesion.instancia.usuario?.rol == RolUsuario.recepcion ||
      ServicioSesion.instancia.usuario?.rol == RolUsuario.admin;
  Future<Caja> abrir(DesgloseEfectivo desglose) async {
    if (!_puedeOperar())
      throw StateError('Solo recepción o administración puede abrir caja.');
    if (cajaActual != null) throw StateError('Ya tienes una caja abierta.');
    final u = ServicioSesion.instancia.usuario!;
    final now = DateTime.now();
    final remoto = await ApiClient.instance.openShift(
      desglose.total,
      breakdown: desglose.toJson(),
    );
    final cajaApi = Caja(
      id: 'api-shift-${remoto['id']}',
      usuarioId: (remoto['user_id'] ?? u.id).toString(),
      aperturaAt:
          DateTime.tryParse(remoto['opened_at']?.toString() ?? '') ?? now,
      montoApertura:
          double.tryParse(remoto['opening_amount']?.toString() ?? '') ??
          desglose.total,
      desgloseApertura: remoto['opening_breakdown'] is Map
          ? DesgloseEfectivo.fromJson(
              Map<String, dynamic>.from(remoto['opening_breakdown'] as Map),
            )
          : desglose,
    );
    _cajas.removeWhere((x) => x.id.startsWith('api-shift-') && x.abierta);
    _cajas.add(cajaApi);
    await _guardar();
    notifyListeners();
    ServicioNotificaciones.instancia.notificarReservasAlAbrirCaja(
      ServicioReservas.instancia.reservas,
    );
    return cajaApi;
  }

  double esperadoAlCerrar(double netoTurno) {
    final remoto = double.tryParse(
      _resumenServidor?['expected_amount']?.toString() ?? '',
    );
    return remoto ??
        (((cajaActual?.montoApertura ?? 0) + netoTurno) * 100).round() / 100;
  }

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
      breakdown: desglose.toJson(),
    );
    final shift = response['shift'] is Map
        ? Map<String, dynamic>.from(response['shift'] as Map)
        : const <String, dynamic>{};
    final diferenciaApi =
        double.tryParse(shift['difference']?.toString() ?? '') ?? diferencia;
    final fechaCierreApi = DateTime.tryParse(
      shift['closed_at']?.toString() ?? '',
    );
    _datosTurnoServidor = shift;
    _resumenServidor = response['summary'] is Map
        ? Map<String, dynamic>.from(response['summary'] as Map)
        : _resumenServidor;
    _ventasServidor = _mapasDe(response['sales']).isEmpty
        ? _ventasServidor
        : _mapasDe(response['sales']);
    _gastosServidor = _mapasDe(response['expenses']).isEmpty
        ? _gastosServidor
        : _mapasDe(response['expenses']);
    _comprasServidor = _mapasDe(response['purchases']).isEmpty
        ? _comprasServidor
        : _mapasDe(response['purchases']);
    final cerrada = c.cerrar(
      fecha: fechaCierreApi ?? cierreAt ?? DateTime.now(),
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
