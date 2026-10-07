import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/servicio_sesion.dart';
import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';
import 'contenedor_principal.dart';
import 'pantalla_solicitar_usuario.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _EstadoPantallaLogin();
}

class _EstadoPantallaLogin extends State<PantallaLogin> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorUsuario = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    if (!_claveFormulario.currentState!.validate()) return;

    // TODO: validar usuario y contraseña contra el servidor / base de datos.
    ServicioSesion.instancia.iniciarSesion(
      Usuario(nombre: _controladorUsuario.text.trim(), cargo: 'Recepción'),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ContenedorPrincipal()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoLogin,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _claveFormulario,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo del hotel (provisional: reemplazar por Image.asset)
                      Image.asset(
                        'assets/imagenes/logo_hotel.jpg',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error al cargar el logo: $error');
                          return const Icon(
                            Icons.hotel,
                            size: 80,
                            color: ColoresApp.primario,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nombre del hotel',
                        style: EstilosTexto.tituloLogin,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _controladorUsuario,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Ingresa tu usuario'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controladorContrasena,
                        obscureText: _ocultarContrasena,
                        onFieldSubmitted: (_) => _iniciarSesion(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarContrasena
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _ocultarContrasena = !_ocultarContrasena,
                            ),
                          ),
                        ),
                        validator: (valor) => (valor == null || valor.isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _iniciarSesion,
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PantallaSolicitarUsuario(),
                          ),
                        ),
                        child: const Text('Solicitar un usuario nuevo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
