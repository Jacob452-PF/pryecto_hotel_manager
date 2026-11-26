import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/usuario.dart';
import '../servicios/api_client.dart';
import '../servicios/servicio_sesion.dart';
import 'contenedor_principal.dart';
import 'pantalla_login.dart';

/// Presenta el tutorial una sola vez en el dispositivo, antes del primer login.
class PantallaInicioApp extends StatefulWidget {
  const PantallaInicioApp({super.key});

  @override
  State<PantallaInicioApp> createState() => _PantallaInicioAppState();
}

class _PantallaInicioAppState extends State<PantallaInicioApp> {
  static const _claveTutorial = 'tutorial_inicio_completado_v1';
  bool _cargando = true;
  bool _mostrarTutorial = false;
  bool _sesionRestaurada = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final completado = prefs.getBool(_claveTutorial) ?? false;
    if (!completado) {
      if (mounted) {
        setState(() {
          _mostrarTutorial = true;
          _cargando = false;
        });
      }
      return;
    }
    await _restaurarSesion();
  }

  Future<void> _finalizarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveTutorial, true);
    if (mounted) {
      setState(() {
        _mostrarTutorial = false;
        _cargando = true;
      });
      await _restaurarSesion();
    }
  }

  Future<void> _restaurarSesion() async {
    final token = await ApiClient.instance.getToken();
    Usuario? guardado;
    var validarEnFondo = true;
    if (token != null) {
      guardado = await ServicioSesion.instancia.usuarioGuardado();
      if (guardado == null) {
        try {
          final remoto = await ApiClient.instance.me().timeout(
            const Duration(seconds: 8),
          );
          guardado = Usuario.fromApiJson(remoto);
          await ServicioSesion.instancia.guardarUsuario(guardado);
          validarEnFondo = false;
        } on Object catch (_) {
          // Sin perfil local ni acceso al API no hay datos suficientes para
          // reconstruir la identidad; se conserva el token para reintentar.
        }
      }
    }
    if (!mounted) return;
    if (guardado == null) {
      setState(() {
        _sesionRestaurada = false;
        _cargando = false;
      });
      return;
    }
    ServicioSesion.instancia.iniciarSesion(guardado);
    setState(() {
      _sesionRestaurada = true;
      _cargando = false;
    });
    if (validarEnFondo) unawaited(_validarSesionEnServidor());
  }

  Future<void> _validarSesionEnServidor() async {
    try {
      final remoto = Usuario.fromApiJson(await ApiClient.instance.me());
      ServicioSesion.instancia.iniciarSesion(remoto);
      await ServicioSesion.instancia.guardarUsuario(remoto);
    } on Object catch (_) {
      // Un corte de red conserva la sesión local; un 401 activa el cierre
      // centralizado del token desde ApiClient.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_mostrarTutorial)
      return TutorialInicio(onFinalizar: _finalizarTutorial);
    return _sesionRestaurada
        ? const ContenedorPrincipal()
        : const PantallaLogin();
  }
}

class _PasoTutorial {
  final IconData icono;
  final String titulo;
  final String descripcion;

  const _PasoTutorial(this.icono, this.titulo, this.descripcion);
}

class TutorialInicio extends StatefulWidget {
  final Future<void> Function() onFinalizar;
  const TutorialInicio({super.key, required this.onFinalizar});

  @override
  State<TutorialInicio> createState() => _TutorialInicioState();
}

class _TutorialInicioState extends State<TutorialInicio> {
  final _paginas = PageController();
  int _actual = 0;
  bool _guardando = false;

  static const _pasos = [
    _PasoTutorial(
      Icons.login,
      'Inicia sesión',
      'Ingresa con el correo y la contraseña de tu cuenta. Cada usuario ve las funciones que corresponden a su puesto.',
    ),
    _PasoTutorial(
      Icons.point_of_sale,
      'Abre la caja',
      'Al comenzar tu turno, registra el efectivo inicial. La app reutiliza la caja que siga abierta después de recargarla.',
    ),
    _PasoTutorial(
      Icons.hotel,
      'Administra habitaciones',
      'Consulta el estado y los datos de las habitaciones. Registra ventas directas o reservaciones desde sus apartados.',
    ),
    _PasoTutorial(
      Icons.storefront,
      'Usa tienda e inventario',
      'Agrega artículos al carrito, cobra o carga consumos a una estadía. El inventario se sincroniza con la información del servidor.',
    ),
    _PasoTutorial(
      Icons.notifications_active_outlined,
      'Revisa avisos y reportes',
      'Consulta las alertas de estadías, reservas e inventario, y revisa los movimientos al cierre de caja.',
    ),
  ];

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    await widget.onFinalizar();
  }

  void _siguiente() {
    if (_actual == _pasos.length - 1) {
      _terminar();
      return;
    }
    _paginas.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de inicio'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _terminar,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _paginas,
                  itemCount: _pasos.length,
                  onPageChanged: (index) => setState(() => _actual = index),
                  itemBuilder: (context, index) {
                    final item = _pasos[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                color: colores.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icono,
                                size: 68,
                                color: colores.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              item.titulo,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.descripcion,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pasos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _actual ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _actual
                            ? colores.primary
                            : colores.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardando ? null : _siguiente,
                  child: Text(
                    _guardando
                        ? 'Guardando…'
                        : _actual == _pasos.length - 1
                        ? 'Terminar e iniciar sesión'
                        : 'Siguiente',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
