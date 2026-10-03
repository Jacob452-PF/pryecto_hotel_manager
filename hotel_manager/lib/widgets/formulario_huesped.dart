import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario con los datos del huésped: nombre, DUI y teléfono.
/// La pantalla que lo usa crea la clave y los controladores.
class FormularioHuesped extends StatelessWidget {
  final GlobalKey<FormState> claveFormulario;
  final TextEditingController controladorNombre;
  final TextEditingController controladorDui;
  final TextEditingController controladorTelefono;

  const FormularioHuesped({
    super.key,
    required this.claveFormulario,
    required this.controladorNombre,
    required this.controladorDui,
    required this.controladorTelefono,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: claveFormulario,
      child: Column(
        children: [
          TextFormField(
            controller: controladorNombre,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (valor) =>
                (valor == null || valor.trim().isEmpty) ? 'Ingresa el nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controladorDui,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: const InputDecoration(
              labelText: 'DUI',
              helperText: '9 dígitos, sin guiones',
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (valor) =>
                (valor == null || valor.length != 9) ? 'El DUI debe tener 9 dígitos' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controladorTelefono,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              helperText: '8 dígitos, sin guiones',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (valor) =>
                (valor == null || valor.length != 8) ? 'El teléfono debe tener 8 dígitos' : null,
          ),
        ],
      ),
    );
  }
} 