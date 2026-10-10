import 'package:flutter/foundation.dart';

import '../modelos/articulo_tienda.dart';
import '../modelos/huesped_tienda.dart';

/// Una línea del carrito: un artículo con su cantidad.
class LineaCarrito {
  final ArticuloTienda articulo;
  int cantidad;

  LineaCarrito(this.articulo, this.cantidad);

  double get importe => articulo.precio * cantidad;
}

/// Carrito compartido entre la pantalla de tienda, las listas y la hoja del carrito.
/// Vive en memoria por ahora; después se puede guardar en la base de datos.
class CarritoTienda extends ChangeNotifier {
  final List<LineaCarrito> _lineas = [];
  final List<LineaCarrito> _eliminadas = [];
  List<HuespedTienda> _huespedes;
  HuespedTienda? _huesped;

  CarritoTienda({List<HuespedTienda> huespedes = const []})
    : _huespedes = huespedes,
      _huesped = huespedes.isEmpty ? null : huespedes.first;

  List<HuespedTienda> get huespedes => _huespedes;

  List<LineaCarrito> get lineas => List.unmodifiable(_lineas);
  List<LineaCarrito> get eliminadas => List.unmodifiable(_eliminadas);
  HuespedTienda? get huesped => _huesped;

  /// Total de unidades (el número que va en la bolsita).
  int get total => _lineas.fold(0, (s, l) => s + l.cantidad);

  double get subtotal => _lineas.fold(0.0, (s, l) => s + l.importe);

  /// Por ahora sin impuestos ni descuentos: total = subtotal.
  double get totalPagar => subtotal;

  void agregar(ArticuloTienda articulo) {
    final i = _lineas.indexWhere((l) => l.articulo.id == articulo.id);
    if (i >= 0) {
      _lineas[i].cantidad++;
    } else {
      _lineas.add(LineaCarrito(articulo, 1));
    }
    notifyListeners();
  }

  /// Cambia la cantidad; nunca baja de 1 (para quitar se usa [eliminar]).
  void cambiarCantidad(LineaCarrito linea, int delta) {
    final nueva = linea.cantidad + delta;
    if (nueva < 1) return;
    linea.cantidad = nueva;
    notifyListeners();
  }

  void eliminar(LineaCarrito linea) {
    _lineas.remove(linea);
    _eliminadas.add(linea);
    notifyListeners();
  }

  void restaurar(LineaCarrito linea) {
    _eliminadas.remove(linea);
    final i = _lineas.indexWhere((l) => l.articulo.id == linea.articulo.id);
    if (i >= 0) {
      _lineas[i].cantidad += linea.cantidad;
    } else {
      _lineas.add(linea);
    }
    notifyListeners();
  }

  /// Se llama cuando cambian las habitaciones (check-in / check-out).
  /// Conserva al huésped elegido si sigue en una habitación ocupada.
  void actualizarHuespedes(List<HuespedTienda> nuevos) {
    _huespedes = nuevos;
    final sigue = _huesped != null && nuevos.any((h) => h.id == _huesped!.id);
    if (!sigue) _huesped = nuevos.isEmpty ? null : nuevos.first;
    notifyListeners();
  }

  void seleccionarHuesped(HuespedTienda huesped) {
    _huesped = huesped;
    notifyListeners();
  }

  void vaciar() {
    _lineas.clear();
    _eliminadas.clear();
    notifyListeners();
  }
}
