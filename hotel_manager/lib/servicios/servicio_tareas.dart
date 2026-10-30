import 'package:flutter/foundation.dart';

import '../modelos/habitacion.dart';
import '../modelos/notificacion_app.dart';
import '../modelos/solicitud_limpieza.dart';
import '../modelos/solicitud_mantenimiento.dart';
import '../modelos/usuario.dart';
import '../historial/modelos/consumo_cliente.dart';
import '../historial/modelos/turno_caja.dart';
import '../historial/servicios/servicio_consumos.dart';
import '../tienda/datos/articulos_mock.dart';
import 'servicio_auth.dart';
import 'servicio_estadias.dart';
import 'servicio_habitaciones.dart';
import 'servicio_notificaciones.dart';
import 'servicio_sesion.dart';
import 'servicio_storage.dart';

class ServicioTareas extends ChangeNotifier {
  ServicioTareas._();
  static final instancia = ServicioTareas._();
  final List<SolicitudLimpieza> _limpieza = [];
  final List<SolicitudMantenimiento> _mantenimiento = [];
  List<SolicitudLimpieza> get solicitudesLimpieza =>
      List.unmodifiable(_limpieza);
  List<SolicitudMantenimiento> get solicitudesMantenimiento =>
      List.unmodifiable(_mantenimiento);
  Usuario? get _usuario => ServicioSesion.instancia.usuario;

  Future<void> cargar() async {
    final l = await ServicioStorage.instancia.leerLista(
      'hotel.solicitudes_limpieza',
    );
    final m = await ServicioStorage.instancia.leerLista(
      'hotel.solicitudes_mantenimiento',
    );
    _limpieza
      ..clear()
      ..addAll(l.map(SolicitudLimpieza.fromJson));
    _mantenimiento
      ..clear()
      ..addAll(m.map(SolicitudMantenimiento.fromJson));
    for (final t in _limpieza.where(
      (t) => t.estado != EstadoSolicitudLimpieza.lista,
    )) {
      final h = ServicioHabitaciones.instancia.buscar(t.habitacionId);
      if (h != null)
        ServicioHabitaciones.instancia.actualizarPorTarea(
          h.numero,
          estado: h.estado == EstadoHabitacion.ocupada
              ? EstadoHabitacion.ocupadaYLimpieza
              : h.estado,
          limpiezaSolicitada: true,
          asignadoLimpiezaId: t.asignadoA,
          descripcionLimpieza: t.descripcion,
        );
    }
    for (final t in _mantenimiento.where(
      (t) => t.estado != EstadoSolicitudMantenimiento.resuelta,
    )) {
      final h = ServicioHabitaciones.instancia.buscar(t.habitacionId);
      if (h != null)
        ServicioHabitaciones.instancia.actualizarPorTarea(
          h.numero,
          estado: EstadoHabitacion.mantenimiento,
          asignadoMantenimientoId: t.asignadoA,
        );
    }
    notifyListeners();
  }

  Future<void> _guardar() async {
    await ServicioStorage.instancia.guardarLista(
      'hotel.solicitudes_limpieza',
      _limpieza.map((e) => e.toJson()).toList(),
    );
    await ServicioStorage.instancia.guardarLista(
      'hotel.solicitudes_mantenimiento',
      _mantenimiento.map((e) => e.toJson()).toList(),
    );
  }

  bool _puedeRecepcion() =>
      _usuario?.rol == RolUsuario.recepcion ||
      _usuario?.rol == RolUsuario.admin;
  bool _esAdmin() => _usuario?.rol == RolUsuario.admin;
  Future<Usuario> _tecnicoActivo(String id, RolUsuario rol) async {
    final encontrados = (await ServicioAuth.instancia.usuarios()).where(
      (u) => u.id == id && u.rol == rol && u.activo,
    );
    if (encontrados.isEmpty)
      throw StateError(
        'El usuario asignado no está activo o no tiene ese rol.',
      );
    return encontrados.first;
  }

  Future<SolicitudLimpieza> solicitarLimpieza(
    String habitacionId, {
    String? descripcion,
    OrigenLimpieza origen = OrigenLimpieza.recepcion,
    bool solicitudHuesped = false,
  }) async {
    if (!_puedeRecepcion() && !(solicitudHuesped && _usuario == null))
      throw StateError(
        'Solo recepción o administración puede solicitar limpieza.',
      );
    final h = ServicioHabitaciones.instancia.buscar(habitacionId);
    if (h == null ||
        !(h.estado == EstadoHabitacion.ocupada ||
            h.estado == EstadoHabitacion.ocupadaYLimpieza ||
            h.estado == EstadoHabitacion.disponible ||
            h.estado == EstadoHabitacion.limpieza)) {
      throw StateError(
        'La habitación no admite una solicitud de limpieza en su estado actual.',
      );
    }
    if (_limpieza.any(
      (t) =>
          t.habitacionId == habitacionId &&
          t.estado != EstadoSolicitudLimpieza.lista,
    ))
      throw StateError('Ya hay una solicitud de limpieza activa.');
    final ahora = DateTime.now();
    final origenReal = solicitudHuesped
        ? OrigenLimpieza.huesped
        : _usuario?.rol == RolUsuario.admin
        ? OrigenLimpieza.admin
        : origen;
    final t = SolicitudLimpieza(
      id: 'lim-${ahora.microsecondsSinceEpoch}',
      habitacionId: habitacionId,
      origen: origenReal,
      descripcion: descripcion?.trim().isEmpty == true
          ? null
          : descripcion?.trim(),
      createdAt: ahora,
    );
    _limpieza.add(t);
    ServicioHabitaciones.instancia.actualizarPorTarea(
      habitacionId,
      estado:
          h.estado == EstadoHabitacion.disponible ||
              h.estado == EstadoHabitacion.limpieza
          ? EstadoHabitacion.limpieza
          : EstadoHabitacion.ocupadaYLimpieza,
      limpiezaSolicitada: true,
      descripcionLimpieza: t.descripcion,
    );
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'tarea-limpieza-${t.id}',
      titulo: 'Nueva solicitud de limpieza',
      mensaje: 'Habitación $habitacionId requiere limpieza.',
      severidad: SeveridadNotificacion.leve,
    );
    await _guardar();
    notifyListeners();
    return t;
  }

  Future<SolicitudLimpieza> solicitarLimpiezaHuesped(String habitacionId) =>
      solicitarLimpieza(
        habitacionId,
        origen: OrigenLimpieza.huesped,
        solicitudHuesped: true,
      );

  Future<void> asignarLimpieza(String solicitudId, String usuarioId) async {
    if (!_esAdmin())
      throw StateError('Solo administración puede asignar tareas.');
    final i = _limpieza.indexWhere(
      (t) => t.id == solicitudId && t.estado != EstadoSolicitudLimpieza.lista,
    );
    if (i < 0) throw StateError('Solicitud de limpieza no encontrada.');
    final tecnico = await _tecnicoActivo(usuarioId, RolUsuario.limpieza);
    _limpieza[i] = _limpieza[i].copyWith(
      estado: EstadoSolicitudLimpieza.asignada,
      asignadoA: tecnico.id,
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
      _limpieza[i].habitacionId,
      asignadoLimpiezaId: tecnico.id,
    );
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'tarea-limpieza-asignada-$solicitudId',
      titulo: 'Limpieza asignada',
      mensaje: 'Se te asignó la habitación ${_limpieza[i].habitacionId}.',
      severidad: SeveridadNotificacion.leve,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> aceptarLimpieza(String solicitudId) async {
    final user = _usuario;
    if (user?.rol != RolUsuario.limpieza)
      throw StateError('Solo personal de limpieza puede aceptar tareas.');
    final i = _limpieza.indexWhere(
      (t) =>
          t.id == solicitudId &&
          (t.estado == EstadoSolicitudLimpieza.pendiente ||
              (t.estado == EstadoSolicitudLimpieza.asignada &&
                  t.asignadoA == user!.id)),
    );
    if (i < 0)
      throw StateError(
        'La solicitud ya fue tomada o asignada por administración.',
      );
    _limpieza[i] = _limpieza[i].copyWith(
      estado: EstadoSolicitudLimpieza.aceptada,
      asignadoA: user!.id,
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
      _limpieza[i].habitacionId,
      asignadoLimpiezaId: user.id,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> iniciarLimpieza(String solicitudId) async {
    final i = _limpieza.indexWhere((t) => t.id == solicitudId);
    if (i < 0 ||
        _limpieza[i].asignadoA != _usuario?.id ||
        _usuario?.rol != RolUsuario.limpieza)
      throw StateError('Esta tarea no está asignada a tu usuario.');
    if (_limpieza[i].estado != EstadoSolicitudLimpieza.asignada &&
        _limpieza[i].estado != EstadoSolicitudLimpieza.aceptada)
      throw StateError('La tarea no se puede iniciar.');
    _limpieza[i] = _limpieza[i].copyWith(
      estado: EstadoSolicitudLimpieza.en_proceso,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> finalizarLimpieza(String solicitudId) async {
    final i = _limpieza.indexWhere((t) => t.id == solicitudId);
    if (i < 0 ||
        _limpieza[i].asignadoA != _usuario?.id ||
        _usuario?.rol != RolUsuario.limpieza)
      throw StateError('Solo la persona asignada puede cerrar esta tarea.');
    if (_limpieza[i].estado != EstadoSolicitudLimpieza.en_proceso)
      throw StateError('Inicia la tarea antes de marcarla como lista.');
    final h = ServicioHabitaciones.instancia.buscar(_limpieza[i].habitacionId);
    final sigueOcupada =
        h?.estado == EstadoHabitacion.ocupada ||
        h?.estado == EstadoHabitacion.ocupadaYLimpieza;
    if (h == null || (!sigueOcupada && h.estado != EstadoHabitacion.limpieza))
      throw StateError(
        'La habitación no se puede liberar desde su estado actual.',
      );
    if (sigueOcupada) {
      final articuloLimpieza = articulosMock.firstWhere(
        (a) => a.nombre.toLowerCase() == 'limpieza',
      );
      ServicioEstadias.instancia.asegurarEstadiaPredeterminada(h.numero);
      ServicioEstadias.instancia.agregarCargos(h.numero, [
        (articulo: articuloLimpieza, cantidad: 1),
      ]);
      ServicioConsumos.instancia.registrar(
        cliente: h.huesped ?? 'Huésped',
        habitacion: h.numero,
        lineas: [
          LineaConsumo(
            articuloLimpieza.nombre,
            articuloLimpieza.precio,
            1,
            TipoVenta.servicios,
          ),
        ],
      );
    }
    _limpieza[i] = _limpieza[i].copyWith(
      estado: EstadoSolicitudLimpieza.lista,
      cerradaAt: DateTime.now(),
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
        h.numero,
      estado: sigueOcupada
          ? EstadoHabitacion.ocupada
          : EstadoHabitacion.disponible,
      limpiezaSolicitada: false,
      limpiarAsignacionLimpieza: true,
      limpiarDescripcion: true,
    );
    await _guardar();
    notifyListeners();
  }

  Future<SolicitudMantenimiento> solicitarMantenimiento(
    String habitacionId,
    String descripcion,
  ) async {
    if (!_puedeRecepcion())
      throw StateError(
        'Solo recepción o administración puede solicitar mantenimiento.',
      );
    if (descripcion.trim().isEmpty)
      throw ArgumentError('Describe el problema de mantenimiento.');
    final h = ServicioHabitaciones.instancia.buscar(habitacionId);
    if (h == null ||
        h.estado == EstadoHabitacion.ocupada ||
        h.estado == EstadoHabitacion.ocupadaYLimpieza ||
        h.estado == EstadoHabitacion.reservada ||
        h.estado == EstadoHabitacion.limpieza)
      throw StateError(
        'No se puede enviar a mantenimiento en el estado actual.',
      );
    if (_mantenimiento.any(
      (t) =>
          t.habitacionId == habitacionId &&
          t.estado != EstadoSolicitudMantenimiento.resuelta,
    ))
      throw StateError('Ya hay una solicitud de mantenimiento activa.');
    final ahora = DateTime.now();
    final t = SolicitudMantenimiento(
      id: 'man-${ahora.microsecondsSinceEpoch}',
      habitacionId: habitacionId,
      descripcion: descripcion.trim(),
      createdAt: ahora,
    );
    _mantenimiento.add(t);
    ServicioHabitaciones.instancia.actualizarPorTarea(
      habitacionId,
      estado: EstadoHabitacion.mantenimiento,
    );
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'tarea-mantenimiento-${t.id}',
      titulo: 'Nueva solicitud de mantenimiento',
      mensaje: 'Habitación $habitacionId: ${t.descripcion}',
      severidad: SeveridadNotificacion.urgente,
    );
    await _guardar();
    notifyListeners();
    return t;
  }

  Future<void> asignarMantenimiento(
    String solicitudId,
    String usuarioId,
  ) async {
    if (!_esAdmin())
      throw StateError('Solo administración puede asignar tareas.');
    final i = _mantenimiento.indexWhere(
      (t) =>
          t.id == solicitudId &&
          t.estado != EstadoSolicitudMantenimiento.resuelta,
    );
    if (i < 0) throw StateError('Solicitud de mantenimiento no encontrada.');
    final tecnico = await _tecnicoActivo(usuarioId, RolUsuario.mantenimiento);
    _mantenimiento[i] = _mantenimiento[i].copyWith(
      estado: EstadoSolicitudMantenimiento.asignada,
      asignadoA: tecnico.id,
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
      _mantenimiento[i].habitacionId,
      asignadoMantenimientoId: tecnico.id,
    );
    ServicioNotificaciones.instancia.notificarEvento(
      id: 'tarea-mantenimiento-asignada-$solicitudId',
      titulo: 'Mantenimiento asignado',
      mensaje: 'Se te asignó la habitación ${_mantenimiento[i].habitacionId}.',
      severidad: SeveridadNotificacion.urgente,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> aceptarMantenimiento(String solicitudId) async {
    final user = _usuario;
    if (user?.rol != RolUsuario.mantenimiento)
      throw StateError('Solo mantenimiento puede aceptar tareas.');
    final i = _mantenimiento.indexWhere(
      (t) =>
          t.id == solicitudId &&
          (t.estado == EstadoSolicitudMantenimiento.pendiente ||
              (t.estado == EstadoSolicitudMantenimiento.asignada &&
                  t.asignadoA == user!.id)),
    );
    if (i < 0) throw StateError('La solicitud ya fue tomada o asignada.');
    _mantenimiento[i] = _mantenimiento[i].copyWith(
      estado: EstadoSolicitudMantenimiento.aceptada,
      asignadoA: user!.id,
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
      _mantenimiento[i].habitacionId,
      asignadoMantenimientoId: user.id,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> iniciarMantenimiento(String solicitudId) async {
    final i = _mantenimiento.indexWhere((t) => t.id == solicitudId);
    if (i < 0 ||
        _mantenimiento[i].asignadoA != _usuario?.id ||
        _usuario?.rol != RolUsuario.mantenimiento)
      throw StateError('Esta tarea no está asignada a tu usuario.');
    _mantenimiento[i] = _mantenimiento[i].copyWith(
      estado: EstadoSolicitudMantenimiento.en_proceso,
    );
    await _guardar();
    notifyListeners();
  }

  Future<void> finalizarMantenimiento(String solicitudId) async {
    final i = _mantenimiento.indexWhere((t) => t.id == solicitudId);
    if (i < 0 ||
        _mantenimiento[i].asignadoA != _usuario?.id ||
        _usuario?.rol != RolUsuario.mantenimiento)
      throw StateError('Solo la persona asignada puede resolver esta tarea.');
    if (_mantenimiento[i].estado != EstadoSolicitudMantenimiento.en_proceso)
      throw StateError('Inicia la tarea antes de marcarla como resuelta.');
    final h = ServicioHabitaciones.instancia.buscar(
      _mantenimiento[i].habitacionId,
    );
    if (h?.estado != EstadoHabitacion.mantenimiento)
      throw StateError('La habitación no está en mantenimiento.');
    _mantenimiento[i] = _mantenimiento[i].copyWith(
      estado: EstadoSolicitudMantenimiento.resuelta,
      resueltaAt: DateTime.now(),
    );
    ServicioHabitaciones.instancia.actualizarPorTarea(
      h!.numero,
      estado: EstadoHabitacion.disponible,
      limpiarAsignacionMantenimiento: true,
    );
    await _guardar();
    notifyListeners();
  }
}
