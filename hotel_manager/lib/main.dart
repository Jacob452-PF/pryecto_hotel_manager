import 'package:flutter/material.dart';
import 'pantallas/pantalla_login.dart';
import 'servicios/servicio_tema.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lee el color que el usuario eligió la última vez.
  await ServicioTema.instancia.cargar();
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
        debugShowCheckedModeBanner: false,
        theme: TemaApp.crear(ServicioTema.instancia.colorPrimario),
        home: const PantallaLogin(),
      ),
    );
  }
}