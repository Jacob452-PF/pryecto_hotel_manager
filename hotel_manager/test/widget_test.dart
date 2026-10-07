import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_manager/main.dart';

void main() {
  testWidgets('La app abre en el login', (WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Solicitar un usuario nuevo'), findsOneWidget);
  });
}
