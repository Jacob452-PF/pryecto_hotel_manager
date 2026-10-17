import 'package:flutter/material.dart';

import '../utilidades/estilos_historial.dart';

/// Fila de una tabla de 3 columnas: [primera celda] [centro] [monto].
class FilaTabla {
  final Widget primera;
  final String centro;
  final String monto;

  const FilaTabla(this.primera, this.centro, this.monto);
}

/// Celda con icono y texto (para "Tipo" y "Categoría").
class CeldaIcono extends StatelessWidget {
  final IconData icono;
  final String texto;
  const CeldaIcono(this.icono, this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta con título, encabezados, filas y total ("Detalle de ventas/gastos").
class SeccionTabla extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final List<String> encabezados; // 3 textos
  final List<FilaTabla> filas;
  final String etiquetaTotal;
  final String total;

  const SeccionTabla({
    super.key,
    required this.icono,
    required this.titulo,
    required this.encabezados,
    required this.filas,
    required this.etiquetaTotal,
    required this.total,
  });

  static const _flex = [4, 4, 2];

  @override
  Widget build(BuildContext context) {
    const estiloEncabezado = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: fuenteTitulo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Encabezados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: Text(encabezados[0], style: estiloEncabezado),
                ),
                Expanded(
                  flex: _flex[1],
                  child: Center(
                    child: Text(encabezados[1], style: estiloEncabezado),
                  ),
                ),
                Expanded(
                  flex: _flex[2],
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(encabezados[2], style: estiloEncabezado),
                  ),
                ),
              ],
            ),
          ),
          // Filas
          for (final f in filas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                children: [
                  Expanded(flex: _flex[0], child: f.primera),
                  Expanded(
                    flex: _flex[1],
                    child: Center(
                      child: Text(
                        f.centro,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _flex[2],
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        f.monto,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    etiquetaTotal,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
