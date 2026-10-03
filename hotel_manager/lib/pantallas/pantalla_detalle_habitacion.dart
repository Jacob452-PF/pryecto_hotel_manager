import 'package:flutter/material.dart';
import '../modelos/habitacion.dart';

/// Pantalla de destino al tocar una habitación (por completar).
class PantallaDetalleHabitacion extends StatelessWidget {
  final Habitacion habitacion;
  const PantallaDetalleHabitacion({super.key, required this.habitacion});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Habitación ${habitacion.numero}')),
        body: Center(child: Text('Estado: ${habitacion.estado.etiqueta}')),
      );
}