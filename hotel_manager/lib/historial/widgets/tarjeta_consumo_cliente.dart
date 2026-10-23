import 'package:flutter/material.dart';

import '../modelos/consumo_cliente.dart';
import '../pantallas/pantalla_factura_cliente.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';
import 'estado_pago_pill.dart';
import 'etiqueta_pill.dart';

/// Tarjeta de un cliente: estado de pago, lo que gastó (inicial y lo añadido
/// después), sus líneas y botón para ver la factura completa.
///
/// Si se pasa [onCambiarPago] aparece el botón "Marcar como pagado"
/// (se usa en Cierre de caja; en el historial es solo lectura).
class TarjetaConsumoCliente extends StatelessWidget {
  final ConsumoCliente consumo;
  final VoidCallback? onCambiarPago;

  const TarjetaConsumoCliente({
    super.key,
    required this.consumo,
    this.onCambiarPago,
  });

  static const _estiloLinea = TextStyle(fontFamily: fuenteTitulo, fontSize: 13);

  Widget _linea(LineaConsumo l) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(l.nombre, style: _estiloLinea)),
        SizedBox(
          width: 64,
          child: Text(
            dinero(l.precio),
            textAlign: TextAlign.right,
            style: _estiloLinea,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${l.cantidad}',
            textAlign: TextAlign.right,
            style: _estiloLinea,
          ),
        ),
      ],
    ),
  );

  Widget _filaMonto(String texto, String monto, {bool resaltar = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: resaltar ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              monto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: resaltar ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final anadio = consumo.lineasAnadidas.isNotEmpty;
    final n = consumo.productosAnadidos;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  consumo.cliente,
                  style: const TextStyle(
                    fontFamily: fuenteTitulo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              EtiquetaPill(consumo.codigo),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              EstadoPagoPill(pagado: consumo.pagado),
              if (consumo.pagado && consumo.pagadoEn != null) ...[
                const SizedBox(width: 8),
                Text(
                  hora(consumo.pagadoEn!),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
              if (consumo.pagado && consumo.metodoPago.isNotEmpty) ...[
                const SizedBox(width: 8),
                EtiquetaPill(consumo.metodoPago),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Productos', style: TextStyle(fontSize: 11)),
                    Text(
                      '${consumo.articulos} ${consumo.articulos == 1 ? 'Artículo' : 'Artículos'}',
                      style: const TextStyle(
                        fontFamily: fuenteTitulo,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total gastado', style: TextStyle(fontSize: 11)),
                  Text(
                    dinero(consumo.total),
                    style: const TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in consumo.lineasIniciales) _linea(l),
                if (anadio) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      'Añadido después',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final l in consumo.lineasAnadidas) _linea(l),
                ],
              ],
            ),
          ),
          if (anadio) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF8A00)),
              ),
              child: Column(
                children: [
                  _filaMonto(
                    'Gastó al registrarse',
                    dinero(consumo.totalInicial),
                  ),
                  _filaMonto(
                    'Añadió $n ${n == 1 ? 'producto' : 'productos'} después',
                    '+ ${dinero(consumo.totalAnadido)}',
                    resaltar: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaFacturaCliente(consumo: consumo),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Ver factura completa'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (onCambiarPago != null)
                consumo.pagado
                    ? OutlinedButton(
                        onPressed: onCambiarPago,
                        child: const Text('Quitar pago'),
                      )
                    : FilledButton.icon(
                        onPressed: onCambiarPago,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Marcar como pagado'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF22A559),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}


