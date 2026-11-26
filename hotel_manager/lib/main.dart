import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'servicios/servicio_actualizacion.dart';
import 'servicios/servicio_caja.dart';
import 'modelos/usuario.dart';
import 'pantallas/contenedor_principal.dart';
import 'pantallas/pantalla_login.dart';
<<<<<<< Updated upstream
import 'pantallas/pantalla_inicio_app.dart';
=======
import 'servicios/api_client.dart';
import 'servicios/servicio_sesion.dart';
>>>>>>> Stashed changes
import 'servicios/servicio_tema.dart';
import 'servicios/servicio_configuracion.dart';
import 'servicios/servicio_conexion.dart';
import 'servicios/servicio_sesion.dart';
import 'tema/tema_app.dart';
import 'widgets/alerta_conexion.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< Updated upstream
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Lee el color que el usuario eligió la última vez.
=======
>>>>>>> Stashed changes
  await ServicioTema.instancia.cargar();
  await ServicioConfiguracion.instancia.cargar();
  ServicioConexion.instancia;
  ApiClient.instance.onUnauthorized = () {
<<<<<<< Updated upstream
    unawaited(ServicioSesion.instancia.cerrarSesion());
=======
    ServicioActualizacion.instancia.detener();
>>>>>>> Stashed changes
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };
  runApp(const MiApp());
}

class MiApp extends StatefulWidget {
  const MiApp({super.key});

  @override
  State<MiApp> createState() => _MiAppState();
}

class _MiAppState extends State<MiApp> with WidgetsBindingObserver {
  late final Future<bool> _sesionRestaurada = _restaurarSesion();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ServicioActualizacion.instancia.sincronizarAhora());
    }
  }

  Future<bool> _restaurarSesion() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) return false;
    var data = await ApiClient.instance.getCachedUser();
    if (data == null) {
      try {
        data = await ApiClient.instance.me();
        await ApiClient.instance.saveSessionUser(data);
      } catch (_) {
        // Una caída de red no cierra la sesión local.
        return false;
      }
    }
    if (await ApiClient.instance.getToken() == null) return false;
    try {
      ServicioSesion.instancia.iniciarSesion(Usuario.fromApiJson(data));
      // Carga la última caja local antes de mostrar la navegación para no
      // ofrecer una apertura nueva si el turno sigue activo en el servidor.
      try {
        await ServicioCaja.instancia.cargar();
      } catch (_) {}
      try {
        await ServicioCaja.instancia.sincronizar();
      } catch (_) {
        // Conserva la caja local y vuelve a consultar al reconectar.
      }
      ApiClient.instance.startConnectionMonitor();
      ServicioActualizacion.instancia.iniciarAutomatico();
      unawaited(ServicioActualizacion.instancia.sincronizarAhora());
      return true;
    } catch (_) {
      await ApiClient.instance.logout();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioTema.instancia,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: TemaApp.crear(ServicioTema.instancia.paleta),
<<<<<<< Updated upstream
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [child ?? const SizedBox.shrink(), const AlertaConexion()],
        ),
        home: const PantallaInicioApp(),
=======
>>>>>>> Stashed changes
        routes: {'/login': (_) => const PantallaLogin()},
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: ApiClient.instance.connectionLost,
          builder: (context, sinConexion, _) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (sinConexion) const _AvisoConexionPerdida(),
            ],
          ),
        ),
        home: FutureBuilder<bool>(
          future: _sesionRestaurada,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data == true
                ? const ContenedorPrincipal()
                : const PantallaLogin();
          },
        ),
      ),
    );
  }
}

class _AvisoConexionPerdida extends StatelessWidget {
  const _AvisoConexionPerdida();

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 560,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - 36,
              ),
              height: alto * 0.55,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.shade300, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 28),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 72,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Se perdió la conexión',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Revisa tu conexión a internet. La sesión sigue abierta y se reanudará automáticamente al volver la conexión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Intentando reconectar…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
