import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_manager/modelos/caja.dart';
import 'package:hotel_manager/widgets/formulario_desglose_efectivo.dart';

void main() {
  testWidgets('calcula el total contando monedas y billetes', (tester) async {
    DesgloseEfectivo? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormularioDesgloseEfectivo(
              titulo: 'Desglose de apertura (USD)',
              boton: 'Confirmar apertura',
              estiloApertura: true,
              alConfirmar: (desglose) => resultado = desglose,
            ),
          ),
        ),
      ),
    );

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '10');
    await tester.enterText(campos.at(8), '9');
    await tester.pump();

    expect(find.text('\$0.10'), findsOneWidget);
    expect(find.text('\$180.00'), findsOneWidget);
    expect(find.text('Total contado: \$180.10'), findsOneWidget);

    final boton = find.text('Confirmar apertura');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();

    expect(resultado?.total, 180.10);
    expect(resultado?.valores['1c'], 0.10);
    expect(resultado?.valores[r'$20'], 180);
  });
}
