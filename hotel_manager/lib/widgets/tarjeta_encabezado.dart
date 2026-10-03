import 'dart:async';
import 'package:flutter/material.dart';
import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

class TarjetaEncabezado extends StatefulWidget {
  const TarjetaEncabezado({super.key});

  @override
  State<TarjetaEncabezado> createState() => _EstadoTarjetaEncabezado();
}

class _EstadoTarjetaEncabezado extends State<TarjetaEncabezado> {
  late DateTime _ahora;
  Timer? _temporizador;

  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _ahora = DateTime.now();
    _temporizador = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _ahora = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hora = '${_dosDigitos(_ahora.hour)}:${_dosDigitos(_ahora.minute)}:${_dosDigitos(_ahora.second)}';
    final fecha = '${_dias[_ahora.weekday - 1]}, ${_ahora.day} de ${_meses[_ahora.month - 1]}';

    return Card(
      margin: EdgeInsets.zero,
      color: ColoresApp.primario,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Dimensiones.radioGrande)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recepción', style: EstilosTexto.tituloEncabezado),
                    SizedBox(height: 4),
                    Text('Estado de las habitaciones en tiempo real',
                        style: EstilosTexto.subtituloEncabezado),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hora, style: EstilosTexto.horaEncabezado),
                  Text(fecha, style: EstilosTexto.fechaEncabezado),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}