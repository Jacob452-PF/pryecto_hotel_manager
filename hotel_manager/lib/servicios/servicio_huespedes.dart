import 'package:flutter/foundation.dart';

import '../modelos/huesped.dart';
import 'servicio_storage.dart';

class ServicioHuespedes extends ChangeNotifier {
  ServicioHuespedes._();
  static final instancia = ServicioHuespedes._();
  static const _clave = 'hotel.huespedes';
  final List<Huesped> _huespedes = [];
  List<Huesped> get huespedes => List.unmodifiable(_huespedes);
  Huesped? porDui(String dui) {
    final clave = _normalizar(dui);
    for (final h in _huespedes) {
      if (_normalizar(h.dui) == clave) return h;
    }
    return null;
  }

  String _normalizar(String dui) =>
      dui.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

  Future<void> cargar() async {
    _huespedes
      ..clear()
      ..addAll(
        (await ServicioStorage.instancia.leerLista(_clave))
            .map(Huesped.fromJson),
      );
    notifyListeners();
  }

  /// Devuelve el huésped existente por DUI; no duplica el registro por cambios de nombre.
  Future<Huesped> obtenerOCrear({
    required String nombre,
    required String dui,
    required String telefono,
    String? email,
  }) async {
    final doc = _normalizar(dui);
    if (doc.isEmpty) throw ArgumentError('El DUI es obligatorio.');
    final existente = porDui(doc);
    if (existente != null) return existente;
    final h = Huesped(
      id: 'h-${DateTime.now().microsecondsSinceEpoch}',
      nombre: nombre.trim(),
      dui: dui.trim(),
      telefono: telefono.trim(),
      email: email,
      createdAt: DateTime.now(),
    );
    _huespedes.add(h);
    await ServicioStorage.instancia.guardarLista(
      _clave,
      _huespedes.map((e) => e.toJson()).toList(),
    );
    notifyListeners();
    return h;
  }
}
