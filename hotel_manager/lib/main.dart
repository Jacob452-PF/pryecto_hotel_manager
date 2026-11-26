import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'servicios/api_client.dart';

import 'pantallas/pantalla_login.dart';
import 'pantallas/pantalla_inicio_app.dart';
import 'servicios/servicio_tema.dart';
import 'servicios/servicio_configuracion.dart';
import 'servicios/servicio_conexion.dart';
import 'servicios/servicio_sesion.dart';
import 'tema/tema_app.dart';
import 'widgets/alerta_conexion.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Lee el color que el usuario eligió la última vez.
  await ServicioTema.instancia.cargar();
  await ServicioConfiguracion.instancia.cargar();
  ServicioConexion.instancia;
  ApiClient.instance.onUnauthorized = () {
    unawaited(ServicioSesion.instancia.cerrarSesion());
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se vuelve a dibujar cuando el usuario cambia el tema.
    return ListenableBuilder(
      listenable: ServicioTema.instancia,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: TemaApp.crear(ServicioTema.instancia.paleta),
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [child ?? const SizedBox.shrink(), const AlertaConexion()],
        ),
        home: const PantallaInicioApp(),
        routes: {'/login': (_) => const PantallaLogin()},
      ),
    );
  }
}
