import 'dart:async';

import 'package:flutter/material.dart';

import 'pantalla_inicio.dart';
import 'pantalla_perfil_caja.dart';
import '../tienda/tienda.dart';
import '../inventario/inventario.dart';
import '../historial/historial.dart';
import '../modelos/notificacion_app.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_notificaciones.dart';
import '../servicios/servicio_sesion.dart';
import '../servicios/servicio_caja.dart';
import '../servicios/servicio_habitaciones.dart';
import '../servicios/servicio_huespedes.dart';
import '../servicios/servicio_reservas.dart';
import '../servicios/servicio_estadias.dart';
import '../servicios/servicio_tareas.dart';
import '../servicios/servicio_conexion.dart';
import 'pantalla_notificaciones.dart';
import 'pantalla_tareas.dart';
import 'pantalla_agenda.dart';
import 'pantalla_apertura_caja.dart';
import 'pantalla_detalle_habitacion.dart';

class ContenedorPrincipal extends StatefulWidget {
  const ContenedorPrincipal({super.key});

  @override
  State<ContenedorPrincipal> createState() => _EstadoContenedorPrincipal();
}

class _EstadoContenedorPrincipal extends State<ContenedorPrincipal>
    with WidgetsBindingObserver {
  int _indice = 0;
  final ServicioNotificaciones _notificaciones =
      ServicioNotificaciones.instancia;
  String? _ultimaNotificacionId;
  Timer? _temporizadorActualizacion;
  bool _actualizandoDatos = false;

  static final List<Widget> _paginas = <Widget>[
    PantallaInicio(),
    PantallaAgenda(),
    PantallaTienda(),
    PantallaInventario(),
    PantallaHistorial(),
    PantallaPerfilCaja(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _temporizadorActualizacion = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _actualizarDatos(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarDatos();
    });
    _ultimaNotificacionId = _notificaciones.notificaciones.isEmpty
        ? null
        : _notificaciones.notificaciones.first.id;
    _notificaciones.addListener(_mostrarAvisoNuevo);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizadorActualizacion?.cancel();
    _notificaciones.removeListener(_mostrarAvisoNuevo);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _actualizarDatos();
  }

  Future<void> _intentar(Future<void> operacion) async {
    try {
      await operacion;
    } on Object catch (_) {
      // Cada servicio conserva su propio error; una falla no detiene los demás.
    }
  }

  Future<void> _actualizarDatos() async {
    if (_actualizandoDatos || !mounted) return;
    _actualizandoDatos = true;
    final rol = ServicioSesion.instancia.usuario?.rol;
    final tareas = <Future<void>>[
      _intentar(ServicioHabitaciones.instancia.sincronizar()),
      _intentar(ServicioHuespedes.instancia.sincronizar()),
      _intentar(ServicioReservas.instancia.sincronizar()),
      _intentar(ServicioEstadias.instancia.sincronizar()),
      _intentar(ServicioTareas.instancia.sincronizar()),
      if (rol == RolUsuario.admin || rol == RolUsuario.recepcion) ...[
        _intentar(ServicioInventario.instancia.sincronizar()),
        _intentar(ServicioCaja.instancia.sincronizar()),
      ],
    ];
    try {
      await Future.wait(tareas);
    } finally {
      _actualizandoDatos = false;
      _abrirCajaSiNecesaria();
    }
  }

  bool _aperturaOfrecida = false;

  void _abrirCajaSiNecesaria() {
    if (!mounted ||
        _aperturaOfrecida ||
        ServicioSesion.instancia.usuario?.rol != RolUsuario.recepcion ||
        !ServicioCaja.instancia.consultada ||
        ServicioCaja.instancia.cajaActual != null ||
        ServicioConexion.instancia.sinConexion) {
      return;
    }
    _aperturaOfrecida = true;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaAperturaCaja()),
    );
  }

  void _mostrarAvisoNuevo() {
    final lista = _notificaciones.notificaciones;
    if (!mounted || lista.isEmpty || lista.first.id == _ultimaNotificacionId) {
      return;
    }
    final notificacion = lista.first;
    _ultimaNotificacionId = notificacion.id;
    final urgente = notificacion.severidad == SeveridadNotificacion.urgente;
    final color = urgente ? const Color(0xFFD32F2F) : const Color(0xFFF57C00);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          content: Row(
            children: [
              Icon(
                urgente ? Icons.error : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${notificacion.titulo}: ${notificacion.mensaje}'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => _abrirOrigenNotificacion(notificacion),
          ),
        ),
      );
  }

  void _abrirNotificaciones() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaNotificaciones()),
    );
  }

  void _abrirOrigenNotificacion(NotificacionApp notificacion) {
    final habitacion = notificacion.habitacion;
    if (habitacion == null) {
      _abrirNotificaciones();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleHabitacion(numeroHabitacion: habitacion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esTecnico =
        ServicioSesion.instancia.usuario?.rol == RolUsuario.limpieza ||
        ServicioSesion.instancia.usuario?.rol == RolUsuario.mantenimiento;
    final paginas = esTecnico
        ? <Widget>[PantallaTareas(), PantallaPerfilCaja()]
        : _paginas;
    final destinos = esTecnico
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Tienda',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_time),
              selectedIcon: Icon(Icons.access_time_filled),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Manager'),
        actions: [
          if (!esTecnico)
            ListenableBuilder(
              listenable: ServicioNotificaciones.instancia,
              builder: (context, _) {
                final cantidad = ServicioNotificaciones.instancia.noLeidas;
                return IconButton(
                  tooltip: 'Notificaciones',
                  onPressed: _abrirNotificaciones,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (cantidad > 0)
                        Positioned(
                          right: -8,
                          top: -7,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cantidad > 99 ? '99+' : '$cantidad',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: destinos,
      ),
    );
  }
}
