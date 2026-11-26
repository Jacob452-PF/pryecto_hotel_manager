import 'dart:async';

import '../modelos/usuario.dart';
import '../inventario/servicios/servicio_inventario.dart';
import 'servicio_caja.dart';
import 'servicio_estadias.dart';
import 'servicio_habitaciones.dart';
import 'servicio_huespedes.dart';
import 'servicio_reservas.dart';
import 'servicio_sesion.dart';
import 'servicio_tareas.dart';

/// Actualiza periódicamente los datos compartidos de la app desde el servidor.
class ServicioActualizacion {
  ServicioActualizacion._();
  static final instancia = ServicioActualizacion._();

  static const intervalo = Duration(minutes: 1);
  Timer? _reloj;
  bool _sincronizando = false;

  Future<void> sincronizarAhora() async {
    if (_sincronizando) return;
    final usuario = ServicioSesion.instancia.usuario;
    if (usuario == null) return;

    _sincronizando = true;
    try {
      final tareas = <Future<void>>[
        ServicioHabitaciones.instancia.sincronizar(),
        ServicioTareas.instancia.sincronizar(),
      ];
      if (usuario.rol == RolUsuario.admin ||
          usuario.rol == RolUsuario.recepcion) {
        tareas.addAll([
          ServicioHuespedes.instancia.sincronizar(),
          ServicioReservas.instancia.sincronizar(),
          ServicioEstadias.instancia.sincronizar(),
          ServicioInventario.instancia.sincronizar(),
          ServicioCaja.instancia.sincronizar(),
        ]);
      }
      await Future.wait(
        tareas.map((tarea) async {
          try {
            await tarea;
          } catch (_) {
            // Mantiene disponibles los datos anteriores si el servidor falla.
          }
        }),
      );
    } finally {
      _sincronizando = false;
    }
  }

  void iniciarAutomatico() {
    _reloj?.cancel();
    _reloj = Timer.periodic(intervalo, (_) => unawaited(sincronizarAhora()));
  }

  void detener() {
    _reloj?.cancel();
    _reloj = null;
  }
}
