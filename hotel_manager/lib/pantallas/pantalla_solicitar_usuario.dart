import 'dart:async';

import 'package:flutter/material.dart';

import '../tema/estilos_texto.dart';

class PantallaSolicitarUsuario extends StatefulWidget {
  const PantallaSolicitarUsuario({super.key});

  @override
  State<PantallaSolicitarUsuario> createState() =>
      _EstadoPantallaSolicitarUsuario();
}

class _EstadoPantallaSolicitarUsuario extends State<PantallaSolicitarUsuario> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorWhatsapp = TextEditingController();
  String? _cargo;
  DateTime? _fechaNacimiento;
  bool _intentoEnviar = false;

  static const _cargos = [
    'Recepción',
    'Administración',
    'Caja',
    'Limpieza',
    'Mantenimiento',
    'Otro',
  ];

  int? get _edad {
    final fecha = _fechaNacimiento;
    if (fecha == null) return null;
    final hoy = DateTime.now();
    var edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorWhatsapp.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ?? DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Selecciona la fecha de nacimiento',
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  void _enviarSolicitud() {
    setState(() => _intentoEnviar = true);
    if (!_claveFormulario.currentState!.validate() ||
        _fechaNacimiento == null) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PantallaEsperaSolicitud()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar usuario nuevo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _claveFormulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Datos de la solicitud',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Completa tus datos para solicitar acceso al sistema.',
                          textAlign: TextAlign.center,
                          style: EstilosTexto.textoVacio,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _controladorNombre,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (valor) =>
                              valor == null || valor.trim().isEmpty
                              ? 'Ingresa tu nombre completo'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _cargo,
                          decoration: const InputDecoration(
                            labelText: 'Cargo',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          items: _cargos
                              .map(
                                (cargo) => DropdownMenuItem(
                                  value: cargo,
                                  child: Text(cargo),
                                ),
                              )
                              .toList(),
                          onChanged: (cargo) => setState(() => _cargo = cargo),
                          validator: (valor) =>
                              valor == null ? 'Selecciona un cargo' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _controladorWhatsapp,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Número de WhatsApp',
                            hintText: 'Ej. +503 7000 0000',
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                          validator: (valor) =>
                              valor == null || valor.trim().isEmpty
                              ? 'Ingresa tu número de WhatsApp'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _elegirFecha,
                          borderRadius: BorderRadius.circular(18),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha de nacimiento',
                              prefixIcon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                              errorText: _fechaNacimiento == null
                                  ? (_intentoEnviar
                                        ? 'Selecciona tu fecha de nacimiento'
                                        : null)
                                  : null,
                            ),
                            child: Text(
                              _fechaNacimiento == null
                                  ? 'Seleccionar fecha'
                                  : _formatearFecha(_fechaNacimiento!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Edad',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _edad == null
                                ? 'Se calcula con tu fecha de nacimiento'
                                : '$_edad años',
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _enviarSolicitud,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Enviar solicitud'),
                        ),
                      ],
                    ),
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

class PantallaEsperaSolicitud extends StatefulWidget {
  const PantallaEsperaSolicitud({super.key});

  @override
  State<PantallaEsperaSolicitud> createState() =>
      _EstadoPantallaEsperaSolicitud();
}

class _EstadoPantallaEsperaSolicitud extends State<PantallaEsperaSolicitud> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Solicitud en espera',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Estamos preparando tu solicitud. En un momento volverás al inicio de sesión.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
