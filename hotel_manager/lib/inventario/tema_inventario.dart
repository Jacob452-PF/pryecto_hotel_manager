import 'package:flutter/material.dart';

const _fuenteInventario = 'serif';

ThemeData temaInventario(BuildContext context) {
  final tema = Theme.of(context);
  return tema.copyWith(
    textTheme: tema.textTheme.apply(fontFamily: _fuenteInventario),
    primaryTextTheme: tema.primaryTextTheme.apply(
      fontFamily: _fuenteInventario,
    ),
  );
}
