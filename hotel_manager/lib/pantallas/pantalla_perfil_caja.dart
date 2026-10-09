import 'package:flutter/material.dart';

import '../datos/informacion_app.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_sesion.dart';
import '../tema/colores_app.dart';
import '../widgets/tarjeta_opcion_perfil.dart';
import '../widgets/tarjeta_perfil.dart';
import 'pantalla_configuracion.dart';
import 'pantalla_estado_red.dart';
import 'pantalla_login.dart';
import 'pantalla_tema.dart';

/// Perfil de la caja actual: datos de la sesión abierta y ajustes de la app.
class PantallaPerfilCaja extends StatelessWidget {
  const PantallaPerfilCaja({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  void _mostrarAcerca(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: nombreApp,
      applicationVersion: versionApp,
      applicationIcon: const Icon(Icons.hotel, size: 40),
      children: const [Text('Soporte técnico: $contactoSoporte')],
    );
  }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      ServicioSesion.instancia.cerrarSesion();
      // Vuelve al login y borra el historial de pantallas.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
        (ruta) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ServicioSesion.instancia;
    final usuario = sesion.usuario ?? const Usuario(nombre: '—', cargo: '—');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarjetaPerfil(
                usuario: usuario,
                inicioSesion: sesion.inicioSesion,
              ),
              const SizedBox(height: 16),
              TarjetaOpcionPerfil(
                icono: Icons.settings,
                titulo: 'Configuración de la app',
                subtitulo: 'Preferencias, notificaciones y sincronización',
                alTocar: () => _abrir(context, const PantallaConfiguracion()),
              ),
              const SizedBox(height: 12),
              TarjetaOpcionPerfil(
                icono: Icons.wifi,
                titulo: 'Estado de la red',
                subtitulo: 'Verifica la conexión con la base de datos',
                alTocar: () => _abrir(context, const PantallaEstadoRed()),
              ),
              const SizedBox(height: 12),
              TarjetaOpcionPerfil(
                icono: Icons.palette,
                titulo: 'Tema de la app',
                subtitulo: 'Escoge los colores que más te gusten',
                alTocar: () => _abrir(context, const PantallaTema()),
              ),
              const SizedBox(height: 24),
              TarjetaOpcionPerfil(
                icono: Icons.info_outline,
                titulo: 'Acerca de la app',
                subtitulo: 'Versión de la aplicación y soporte técnico',
                alTocar: () => _mostrarAcerca(context),
              ),
              const SizedBox(height: 12),
              TarjetaOpcionPerfil(
                icono: Icons.logout,
                colorIcono: ColoresApp.cancelar,
                titulo: 'Cerrar sesión',
                subtitulo: 'Sal de tu cuenta de forma segura',
                alTocar: () => _confirmarCerrarSesion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
