import 'dart:async';

import 'package:flutter/foundation.dart';

import '../inventario/servicios/servicio_inventario.dart';
import '../modelos/notificacion_app.dart';
import 'servicio_estadias.dart';

/// Vigila estadías e inventario mientras la app está abierta.
class ServicioNotificaciones extends ChangeNotifier {
  ServicioNotificaciones._() {
    ServicioEstadias.instancia.addListener(_revisar);
    ServicioInventario.instancia.addListener(_revisar);
    _revisar();
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) => _revisar());
  }

  static final ServicioNotificaciones instancia = ServicioNotificaciones._();

  Timer? _reloj;
  final List<NotificacionApp> _notificaciones = [];
  final Set<String> _eventosEstadia = {};
  final Map<String, String> _estadoStock = {};

  List<NotificacionApp> get notificaciones =>
      List.unmodifiable(_notificaciones);
  int get noLeidas => _notificaciones.where((n) => !n.leida).length;

  void _agregar({
    required String id,
    required String titulo,
    required String mensaje,
    required SeveridadNotificacion severidad,
  }) {
    _notificaciones.insert(
      0,
      NotificacionApp(
        id: id,
        titulo: titulo,
        mensaje: mensaje,
        fecha: DateTime.now(),
        severidad: severidad,
      ),
    );
    notifyListeners();
  }

  void _revisar() {
    final ahora = DateTime.now();
    for (final entrada in ServicioEstadias.instancia.todas.entries) {
      final habitacion = entrada.key;
      final estadia = entrada.value;
      final clave = '$habitacion-${estadia.entrada.microsecondsSinceEpoch}';
      final restante = estadia.salida.difference(ahora);

      if (restante <= Duration.zero) {
        final id = 'estadia-finalizada-$clave';
        if (_eventosEstadia.add(id)) {
          _agregar(
            id: id,
            titulo: 'Estadía finalizada',
            mensaje: 'La estadía de la habitación $habitacion llegó a su fin.',
            severidad: SeveridadNotificacion.urgente,
          );
        }
      } else if (restante <= const Duration(minutes: 30)) {
        final id = 'estadia-proxima-$clave';
        if (_eventosEstadia.add(id)) {
          final minutos = restante.inMinutes.clamp(1, 30);
          _agregar(
            id: id,
            titulo: 'Estadía próxima a terminar',
            mensaje: 'Habitación $habitacion: quedan cerca de $minutos min.',
            severidad: SeveridadNotificacion.leve,
          );
        }
      }
    }

    for (final producto in ServicioInventario.instancia.productos) {
      final estado = producto.stock <= 0
          ? 'agotado'
          : producto.stockBajo
          ? 'bajo'
          : 'normal';
      final anterior = _estadoStock[producto.id];
      _estadoStock[producto.id] = estado;
      if (estado == anterior || estado == 'normal') continue;

      final severidad = estado == 'agotado'
          ? SeveridadNotificacion.urgente
          : SeveridadNotificacion.leve;
      _agregar(
        id: 'stock-${producto.id}-$estado-${ahora.microsecondsSinceEpoch}',
        titulo: estado == 'agotado' ? 'Producto agotado' : 'Stock bajo',
        mensaje: estado == 'agotado'
            ? '${producto.nombre} se quedó sin existencias.'
            : '${producto.nombre}: quedan ${producto.stock} de ${producto.stockMaximo}.',
        severidad: severidad,
      );
    }
  }

  void marcarTodasLeidas() {
    if (noLeidas == 0) return;
    for (var i = 0; i < _notificaciones.length; i++) {
      _notificaciones[i] = _notificaciones[i].copyWith(leida: true);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    ServicioEstadias.instancia.removeListener(_revisar);
    ServicioInventario.instancia.removeListener(_revisar);
    super.dispose();
  }
}
