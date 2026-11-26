import 'package:flutter/foundation.dart';

import '../modelos/habitacion.dart';
import '../modelos/solicitud_limpieza.dart';
import '../modelos/solicitud_mantenimiento.dart';
import '../modelos/usuario.dart';
import 'api_client.dart';
import 'servicio_habitaciones.dart';
import 'servicio_sesion.dart';

/// Tareas y cambios de estado se leen y escriben en el servicio remoto.
class ServicioTareas extends ChangeNotifier {
  ServicioTareas._();
  static final instancia = ServicioTareas._();

  final List<SolicitudLimpieza> _limpieza = [];
  final List<SolicitudMantenimiento> _mantenimiento = [];
  List<SolicitudLimpieza> get solicitudesLimpieza => List.unmodifiable(_limpieza);
  List<SolicitudMantenimiento> get solicitudesMantenimiento => List.unmodifiable(_mantenimiento);
  bool cargando = false;
  String? error;
  bool _sincronizacionEnCurso = false;
  bool _intentoInicial = false;
  Usuario? get _usuario => ServicioSesion.instancia.usuario;

  Future<void> cargar() => sincronizar();

  Future<void> sincronizar() async {
    if (_sincronizacionEnCurso) return;
    _sincronizacionEnCurso = true;
    cargando = !_intentoInicial;
    error = null;
    notifyListeners();
    try {
      final tasks = <Map<String, dynamic>>[];
      var page = 1;
      var lastPage = 1;
      do {
        final response = await ApiClient.instance.tasks(page: page);
        tasks.addAll(ApiClient.instance.listFromResponse(response)
            .map((row) => Map<String, dynamic>.from(row as Map)));
        if (response is Map) {
          final meta = response['meta'];
          lastPage = int.tryParse(
                (response['last_page'] ?? (meta is Map ? meta['last_page'] : null))
                        ?.toString() ??
                    '',
              ) ??
              page;
        }
        page++;
      } while (page <= lastPage);
      _limpieza
        ..clear()
        ..addAll(tasks.where((t) => t['type'] == 'limpieza').map(_aLimpieza));
      _mantenimiento
        ..clear()
        ..addAll(tasks.where((t) => t['type'] == 'mantenimiento').map(_aMantenimiento));
    } on Object catch (e) {
      // Conserva la última respuesta válida durante fallas temporales de red.
      // La pantalla muestra el error y permite reintentar, sin vaciar la lista.
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      _intentoInicial = true;
      _sincronizacionEnCurso = false;
      notifyListeners();
    }
  }

  SolicitudLimpieza _aLimpieza(Map<String, dynamic> j) {
    final room = j['room'] is Map ? Map<String, dynamic>.from(j['room'] as Map) : const <String, dynamic>{};
    final status = j['status']?.toString();
    return SolicitudLimpieza(
      id: j['id'].toString(),
      habitacionId: (room['number'] ?? j['room_id']).toString(),
      origen: OrigenLimpieza.recepcion,
      descripcion: j['description']?.toString(),
      estado: switch (status) {
        'asignada' => EstadoSolicitudLimpieza.asignada,
        'en_progreso' => EstadoSolicitudLimpieza.en_proceso,
        'completada' || 'cancelada' => EstadoSolicitudLimpieza.lista,
        _ => EstadoSolicitudLimpieza.pendiente,
      },
      asignadoA: j['assigned_to']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      cerradaAt: DateTime.tryParse(j['completed_at']?.toString() ?? ''),
    );
  }

  SolicitudMantenimiento _aMantenimiento(Map<String, dynamic> j) {
    final room = j['room'] is Map ? Map<String, dynamic>.from(j['room'] as Map) : const <String, dynamic>{};
    final status = j['status']?.toString();
    return SolicitudMantenimiento(
      id: j['id'].toString(),
      habitacionId: (room['number'] ?? j['room_id']).toString(),
      descripcion: j['description']?.toString() ?? '',
      estado: switch (status) {
        'asignada' => EstadoSolicitudMantenimiento.asignada,
        'en_progreso' => EstadoSolicitudMantenimiento.en_proceso,
        'completada' || 'cancelada' => EstadoSolicitudMantenimiento.resuelta,
        _ => EstadoSolicitudMantenimiento.pendiente,
      },
      asignadoA: j['assigned_to']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      resueltaAt: DateTime.tryParse(j['completed_at']?.toString() ?? ''),
    );
  }

  int _roomApiId(String numero) {
    final room = ServicioHabitaciones.instancia.buscar(numero);
    final id = int.tryParse(room?.id ?? '');
    if (id == null) throw StateError('La habitación no tiene ID del servidor.');
    return id;
  }

  bool _puedeRecepcion() => _usuario?.rol == RolUsuario.recepcion || _usuario?.rol == RolUsuario.admin;
  Future<SolicitudLimpieza> solicitarLimpieza(
    String habitacionId, {
    String? descripcion,
    OrigenLimpieza origen = OrigenLimpieza.recepcion,
    bool solicitudHuesped = false,
  }) async {
    if (!_puedeRecepcion()) throw StateError('Solo recepción o administración puede solicitar limpieza.');
    final room = ServicioHabitaciones.instancia.buscar(habitacionId);
    if (room == null ||
        (room.estado == EstadoHabitacion.ocupadaYLimpieza &&
            room.limpiezaSolicitada)) {
      throw StateError('No se puede solicitar limpieza para esta habitación en su estado actual.');
    }
    final response = await ApiClient.instance.createTask({
      'room_id': _roomApiId(habitacionId),
      'type': 'limpieza',
      'description': descripcion?.trim().isEmpty == true ? null : descripcion?.trim(),
    });
    await Future.wait([sincronizar(), ServicioHabitaciones.instancia.sincronizar()]);
    return _aLimpieza(response);
  }

  Future<SolicitudLimpieza> solicitarLimpiezaHuesped(String habitacionId) =>
      solicitarLimpieza(habitacionId, origen: OrigenLimpieza.huesped, solicitudHuesped: true);

  Future<void> asignarLimpieza(String taskId, String userId) async => _asignar(taskId, userId);
  Future<void> asignarMantenimiento(String taskId, String userId) async => _asignar(taskId, userId);

  Future<void> _asignar(String taskId, String userId) async {
    if (!_puedeRecepcion()) throw StateError('Solo recepción o administración puede asignar tareas.');
    await ApiClient.instance.assignTask(taskId, userId);
    await sincronizar();
  }

  /// La API pasa directamente de pendiente/asignada a en_progreso; no existe
  /// una operación separada de aceptación.
  Future<void> aceptarLimpieza(String id) => iniciarLimpieza(id);
  Future<void> aceptarMantenimiento(String id) => iniciarMantenimiento(id);

  Future<void> iniciarLimpieza(String id) async => _actualizarEstado(id, 'en_progreso');
  Future<void> finalizarLimpieza(String id) async {
    await _actualizarEstado(id, 'completada');
    await ServicioHabitaciones.instancia.sincronizar();
  }

  Future<SolicitudMantenimiento> solicitarMantenimiento(String room, String descripcion) async {
    if (!_puedeRecepcion()) throw StateError('Solo recepción o administración puede solicitar mantenimiento.');
    if (descripcion.trim().isEmpty) throw ArgumentError('Describe el problema de mantenimiento.');
    final response = await ApiClient.instance.createTask({
      'room_id': _roomApiId(room),
      'type': 'mantenimiento',
      'description': descripcion.trim(),
    });
    await Future.wait([sincronizar(), ServicioHabitaciones.instancia.sincronizar()]);
    return _aMantenimiento(response);
  }

  Future<void> iniciarMantenimiento(String id) async => _actualizarEstado(id, 'en_progreso');
  Future<void> finalizarMantenimiento(String id) async {
    await _actualizarEstado(id, 'completada');
    await ServicioHabitaciones.instancia.sincronizar();
  }

  Future<void> _actualizarEstado(String id, String status) async {
    await ApiClient.instance.updateTaskStatus(id, status);
    await sincronizar();
  }
}
