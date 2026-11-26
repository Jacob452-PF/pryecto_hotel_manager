import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'servicios/api_client.dart';

import 'pantallas/pantalla_login.dart';
import 'servicios/servicio_tema.dart';
import 'servicios/servicio_configuracion.dart';
import 'tema/tema_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Lee el color que el usuario eligió la última vez.
  await ServicioTema.instancia.cargar();
  await ServicioConfiguracion.instancia.cargar();
  ApiClient.instance.onUnauthorized = () {
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
        home: const PantallaLogin(),
        routes: {'/login': (_) => const PantallaLogin()},
      ),
    );
  }
}
