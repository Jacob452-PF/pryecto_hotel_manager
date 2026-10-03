import 'package:flutter/material.dart';

class PantallaSolicitarUsuario extends StatelessWidget {
  const PantallaSolicitarUsuario({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Solicitar usuario nuevo')),
        body: const Center(child: Text('Formulario de solicitud (por hacer)')),
      );
}