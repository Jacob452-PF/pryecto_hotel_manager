import 'package:flutter/material.dart';

import 'pantallas/pantalla_login.dart';
import 'servicios/servicio_tema.dart';
import 'servicios/servicio_configuracion.dart';
import 'servicios/servicio_reservas.dart';
import 'servicios/servicio_estadias.dart';
import 'servicios/servicio_huespedes.dart';
import 'servicios/servicio_habitaciones.dart';
import 'servicios/servicio_tareas.dart';
import 'servicios/servicio_caja.dart';
import 'servicios/servicio_abonos.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lee el color que el usuario eligió la última vez.
  await ServicioTema.instancia.cargar();
  await ServicioConfiguracion.instancia.cargar();
  await ServicioHuespedes.instancia.cargar();
  await ServicioHabitaciones.instancia.cargar();
  await ServicioEstadias.instancia.cargar();
  await ServicioReservas.instancia.cargar();
  await ServicioTareas.instancia.cargar();
  await ServicioCaja.instancia.cargar();
  await ServicioAbonos.instancia.cargar();
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
        theme: TemaApp.crear(ServicioTema.instancia.paleta),
        home: const PantallaLogin(),
      ),
    );
  }
}
