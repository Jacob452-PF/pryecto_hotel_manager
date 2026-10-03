import 'package:flutter/material.dart';
import 'pantallas/pantalla_login.dart';
import 'tema/tema_app.dart';

void main() => runApp(const MiApp());

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TemaApp.claro,
        home: const PantallaLogin(),
      );
}