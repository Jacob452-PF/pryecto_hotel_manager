import 'package:flutter/material.dart';
import '../tema/estilos_texto.dart';

/// Contador con botones para aumentar o disminuir (horas, noches).
class ContadorCantidad extends StatelessWidget {
  final String etiqueta;
  final int valor;
  final int minimo;
  final ValueChanged<int> alCambiar;

  const ContadorCantidad({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
    this.minimo = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(etiqueta, style: EstilosTexto.etiquetaOpcion),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: valor > minimo ? () => alCambiar(valor - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: EstilosTexto.numeroContador,
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => alCambiar(valor + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
} 