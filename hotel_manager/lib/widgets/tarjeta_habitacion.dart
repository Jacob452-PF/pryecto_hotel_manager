import 'package:flutter/material.dart';

import '../modelos/habitacion.dart';
import '../pantallas/pantalla_detalle_habitacion.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

class TarjetaHabitacion extends StatelessWidget {
  final Habitacion habitacion;
  const TarjetaHabitacion({super.key, required this.habitacion});

  @override
  Widget build(BuildContext context) {
    final estado = habitacion.estado;
    final estadoVisible = switch (estado) {
      EstadoHabitacion.limpieza => EstadoHabitacion.disponible,
      EstadoHabitacion.ocupadaYLimpieza => EstadoHabitacion.ocupada,
      _ => estado,
    };
    final radio = BorderRadius.circular(Dimensiones.radioTarjeta);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
      color: estadoVisible.color.withValues(alpha: 0.12),
        borderRadius: radio,
        child: InkWell(
          borderRadius: radio,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaDetalleHabitacion(
                numeroHabitacion: habitacion.numero,
              ),
            ),
          ),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: radio,
              border: Border.all(color: estadoVisible.color.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      habitacion.numero,
                      style: EstilosTexto.numeroHabitacion,
                    ),
                    Icon(estadoVisible.icono, color: estadoVisible.color, size: 20),
                  ],
                ),
                Text(
                  '${habitacion.camas} ${habitacion.camas == 1 ? 'cama' : 'camas'}',
                  style: EstilosTexto.detalleHabitacion,
                ),
                Text(
                  estadoVisible.etiqueta,
                  style: EstilosTexto.estadoHabitacion.copyWith(
                    color: estadoVisible.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
