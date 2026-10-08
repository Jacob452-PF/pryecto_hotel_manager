import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';
import 'pantalla_acerca_app.dart';
import 'pantalla_login.dart';
import 'pantalla_tema_app.dart';

class PantallaPerfilCaja extends StatelessWidget {
  const PantallaPerfilCaja({super.key});

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final cerrar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de la caja actual?'),
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

    if (cerrar != true || !context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _EncabezadoPerfil(),
            const SizedBox(height: 16),
            _OpcionPerfil(
              icono: Icons.settings,
              titulo: 'Configuración de la app',
              subtitulo: 'Preferencias, notificaciones y personalización',
              alTocar: () {},
            ),
            const SizedBox(height: 10),
            _OpcionPerfil(
              icono: Icons.wifi,
              titulo: 'Estado de la red',
              subtitulo: 'Verifica la conexión con la base de datos',
              alTocar: () {},
            ),
            const SizedBox(height: 10),
            _OpcionPerfil(
              icono: Icons.brush,
              titulo: 'Tema de la app',
              subtitulo: 'Escoge los colores que más te gusten',
              alTocar: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaTemaApp()),
              ),
            ),
            const SizedBox(height: 24),
            _OpcionPerfil(
              icono: Icons.info_outline,
              titulo: 'Acerca de la app',
              subtitulo: 'Versión de la aplicación y soporte técnico',
              alTocar: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaAcercaApp()),
              ),
            ),
            const SizedBox(height: 24),
            _OpcionPerfil(
              icono: Icons.logout,
              titulo: 'Cerrar sesión',
              subtitulo: 'Salir de la cuenta de forma segura',
              colorIcono: ColoresApp.cancelar,
              alTocar: () => _confirmarCerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoPerfil extends StatelessWidget {
  const _EncabezadoPerfil();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: ColoresApp.primario,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: ColoresApp.sobrePrimario,
            size: 48,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DatoPerfil(etiqueta: 'Nombre', valor: 'Caja principal'),
                  SizedBox(height: 8),
                  _DatoPerfil(etiqueta: 'Cargo', valor: 'Recepción'),
                  SizedBox(height: 8),
                  _DatoPerfil(etiqueta: 'Edad', valor: 'No registrada'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoPerfil({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$etiqueta:', style: EstilosTexto.etiquetaInformacion),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ColoresApp.textoSecundario),
              ),
            ),
            child: Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EstilosTexto.valorInformacion.copyWith(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;
  final Color? colorIcono;

  const _OpcionPerfil({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alTocar,
    this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorIcono ?? ColoresApp.primario;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icono, color: color, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: EstilosTexto.tituloTarjeta),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: EstilosTexto.detalleOpcion),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ColoresApp.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
