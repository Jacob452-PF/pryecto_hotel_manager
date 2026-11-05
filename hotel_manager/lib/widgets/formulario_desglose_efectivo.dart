import 'package:flutter/material.dart';

import '../modelos/caja.dart';

class FormularioDesgloseEfectivo extends StatefulWidget {
  final String titulo;
  final String boton;
  final DesgloseEfectivo? inicial;
  final double? montoEsperado;
  final ValueChanged<DesgloseEfectivo> alConfirmar;
  final VoidCallback? alCancelar;
  const FormularioDesgloseEfectivo({
    super.key,
    required this.titulo,
    required this.boton,
    required this.alConfirmar,
    this.inicial,
    this.montoEsperado,
    this.alCancelar,
  });
  @override
  State<FormularioDesgloseEfectivo> createState() =>
      _FormularioDesgloseEfectivoState();
}

class _FormularioDesgloseEfectivoState
    extends State<FormularioDesgloseEfectivo> {
  late final Map<String, TextEditingController> _campos = {
    for (final key in denominacionesUsd.keys)
      key: TextEditingController(
        text: (widget.inicial?.valores[key] ?? 0).toStringAsFixed(2),
      ),
  };
  @override
  void dispose() {
    for (final c in _campos.values) c.dispose();
    super.dispose();
  }

  DesgloseEfectivo get _desglose => DesgloseEfectivo(
    valores: {
      for (final e in _campos.entries)
        e.key:
            ((double.tryParse(e.value.text.trim().replaceAll(',', '.')) ?? 0)
                        .clamp(0, 100000000) *
                    100)
                .roundToDouble() /
            100,
    },
  );
  String _usd(double value) => '\$${value.toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context) {
    final d = _desglose;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.titulo, style: Theme.of(context).textTheme.titleLarge),
        if (widget.montoEsperado != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Efectivo esperado: ${_usd(widget.montoEsperado!)}'),
          ),
        const SizedBox(height: 8),
        for (final denomination in denominacionesUsd.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 54, child: Text(denomination.key)),
                Expanded(
                  child: TextFormField(
                    controller: _campos[denomination.key],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor contado',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Text(
                    _usd(d.valores[denomination.key] ?? 0),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 18),
        Text(
          'Total contado: ${_usd(d.total)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.alCancelar != null)
          TextButton(
            onPressed: widget.alCancelar,
            child: const Text('Cancelar'),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => widget.alConfirmar(d),
          child: Text(widget.boton),
        ),
      ],
    );
  }
}
