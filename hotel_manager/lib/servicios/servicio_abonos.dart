import 'package:flutter/foundation.dart';

import '../modelos/abono.dart';
import '../servicios/servicio_caja.dart';
import '../servicios/servicio_sesion.dart';
import 'servicio_storage.dart';

class ServicioAbonos extends ChangeNotifier {
  ServicioAbonos._();
  static final instancia = ServicioAbonos._();
  final List<Abono> _abonos = [];
  List<Abono> get abonos => List.unmodifiable(_abonos);
  Future<void> cargar() async {
    _abonos
      ..clear()
      ..addAll(
        (await ServicioStorage.instancia.leerLista('hotel.abonos'))
            .map(Abono.fromJson),
      );
    notifyListeners();
  }

  List<Abono> paraFactura(String facturaId) =>
      List.unmodifiable(_abonos.where((a) => a.facturaId == facturaId));
  double abonado(String facturaId) => _abonos
      .where((a) => a.facturaId == facturaId)
      .fold(0.0, (s, a) => s + a.monto);
  double efectivoRecibidoEnCaja(String cajaId) => _abonos
      .where((a) => a.cajaId == cajaId && a.metodo == MetodoAbono.efectivo)
      .fold(0.0, (s, a) => s + a.monto);

  Future<Abono> registrar({
    required String facturaId,
    required double monto,
    required double saldoDisponible,
    required MetodoAbono metodo,
  }) async {
    final caja = ServicioCaja.instancia.cajaActual;
    final usuario = ServicioSesion.instancia.usuario;
    if (caja == null || usuario == null)
      throw StateError('Abre una caja para recibir y registrar abonos.');
    if (monto <= 0 || monto > saldoDisponible + 0.001)
      throw ArgumentError(
        'El abono debe ser mayor que cero y no superar el saldo pendiente.',
      );
    final ahora = DateTime.now();
    final a = Abono(
      id: 'abo-${ahora.microsecondsSinceEpoch}',
      facturaId: facturaId,
      monto: monto,
      metodo: metodo,
      usuarioId: usuario.id,
      cajaId: caja.id,
      createdAt: ahora,
    );
    _abonos.add(a);
    await ServicioStorage.instancia.guardarLista(
      'hotel.abonos',
      _abonos.map((e) => e.toJson()).toList(),
    );
    notifyListeners();
    return a;
  }
}
