import 'package:flutter/material.dart';

import '../modelos/abono.dart';
import '../utilidades/formato.dart';

typedef DatosCobro = ({
  double monto,
  MetodoAbono metodo,
  double efectivoEntregado,
});

Future<DatosCobro?> mostrarDialogoCobro(
  BuildContext context, {
  required double saldo,
  bool permitirAbono = false,
}) async {
  final montoCtrl = TextEditingController(
    text: permitirAbono ? '' : saldo.toStringAsFixed(2),
  );
  final efectivoCtrl = TextEditingController();
  var metodo = MetodoAbono.efectivo;
  DatosCobro? parsear() {
    final monto = double.tryParse(montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0 || monto > saldo + .001) return null;
    final efectivo = metodo == MetodoAbono.efectivo
        ? (double.tryParse(efectivoCtrl.text.trim().replaceAll(',', '.')) ?? 0)
        : monto;
    if (metodo == MetodoAbono.efectivo && efectivo < monto) return null;
    return (monto: monto, metodo: metodo, efectivoEntregado: efectivo);
  }

  final cobroCapturado = await showDialog<DatosCobro>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, refresh) {
        final cobro = parsear();
        final entregado =
            double.tryParse(efectivoCtrl.text.replaceAll(',', '.')) ?? 0;
        return AlertDialog(
          title: Text(permitirAbono ? 'Abonar a la factura' : 'Cobrar factura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo pendiente: ${formatearDinero(saldo)}'),
              if (permitirAbono)
                TextField(
                  controller: montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto a abonar',
                  ),
                  onChanged: (_) => refresh(() {}),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<MetodoAbono>(
                initialValue: metodo,
                decoration: const InputDecoration(labelText: 'Forma de pago'),
                items: [
                  for (final m in MetodoAbono.values)
                    DropdownMenuItem(value: m, child: Text(m.etiqueta)),
                ],
                onChanged: (v) => refresh(() {
                  if (v != null) metodo = v;
                }),
              ),
              if (metodo == MetodoAbono.efectivo) ...[
                TextField(
                  controller: efectivoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Efectivo recibido',
                  ),
                  onChanged: (_) => refresh(() {}),
                ),
                if (entregado >= (cobro?.monto ?? double.infinity))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Cambio: ${formatearDinero(entregado - (cobro?.monto ?? 0))}',
                      ),
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: cobro == null ? null : () => Navigator.pop(ctx, cobro),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    ),
  );
  montoCtrl.dispose();
  efectivoCtrl.dispose();
  if (cobroCapturado == null || !context.mounted) return null;

  final cambio = cobroCapturado.efectivoEntregado - cobroCapturado.monto;
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar cobro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monto a cobrar: ${formatearDinero(cobroCapturado.monto)}'),
          const SizedBox(height: 6),
          Text('Forma de pago: ${cobroCapturado.metodo.etiqueta}'),
          if (cobroCapturado.metodo == MetodoAbono.efectivo) ...[
            const SizedBox(height: 6),
            Text(
              'Efectivo recibido: ${formatearDinero(cobroCapturado.efectivoEntregado)}',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'VUELTO A DEVOLVER\n${formatearDinero(cambio)}',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar cobro'),
        ),
      ],
    ),
  );
  return confirmado == true ? cobroCapturado : null;
}
