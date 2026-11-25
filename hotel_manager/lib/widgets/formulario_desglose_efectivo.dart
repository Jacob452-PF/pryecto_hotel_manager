import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/caja.dart';

class FormularioDesgloseEfectivo extends StatefulWidget {
  final String titulo;
  final String boton;
  final DesgloseEfectivo? inicial;
  final double? montoEsperado;
  final bool estiloApertura;
  final ValueChanged<DesgloseEfectivo> alConfirmar;
  final VoidCallback? alCancelar;
  const FormularioDesgloseEfectivo({
    super.key,
    required this.titulo,
    required this.boton,
    required this.alConfirmar,
    this.inicial,
    this.montoEsperado,
    this.estiloApertura = false,
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
        text: widget.inicial == null
            ? ''
            : ((widget.inicial!.valores[key] ?? 0) / denominacionesUsd[key]!)
                  .round()
                  .toString(),
      ),
  };
  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  DesgloseEfectivo get _desglose => DesgloseEfectivo(
    valores: {
      for (final e in _campos.entries)
        e.key:
            (((int.tryParse(e.value.text.trim()) ?? 0).clamp(0, 100000000) *
                (denominacionesUsd[e.key]! * 100).round()) /
            100),
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
        Text(
          widget.titulo,
          style: widget.estiloApertura
              ? Theme.of(context).textTheme.headlineSmall
              : Theme.of(context).textTheme.titleLarge,
        ),
        if (widget.montoEsperado != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Efectivo esperado: ${_usd(widget.montoEsperado!)}'),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Ingresa cuántas monedas o billetes hay de cada denominación.',
          ),
        ),
        const SizedBox(height: 8),
        for (final denomination in denominacionesUsd.entries)
          Builder(
            builder: (context) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: widget.estiloApertura ? 4 : 3,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 54, child: Text(denomination.key)),
                    Expanded(
                      child: TextFormField(
                        controller: _campos[denomination.key],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cantidad de piezas',
                          isDense: !widget.estiloApertura,
                          contentPadding: widget.estiloApertura
                              ? const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                )
                              : null,
                          border: widget.estiloApertura
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                )
                              : null,
                          enabledBorder: widget.estiloApertura
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                )
                              : null,
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
              );
            },
          ),
        const Divider(height: 18),
        Text(
          'Total contado: ${_usd(d.total)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.alCancelar != null)
          widget.estiloApertura
              ? Center(
                  child: TextButton(
                    onPressed: widget.alCancelar,
                    child: const Text('Cancelar'),
                  ),
                )
              : TextButton(
                  onPressed: widget.alCancelar,
                  child: const Text('Cancelar'),
                ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => widget.alConfirmar(d),
          style: widget.estiloApertura
              ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))
              : null,
          child: Text(widget.boton),
        ),
      ],
    );
  }
}
