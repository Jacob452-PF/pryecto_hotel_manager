import 'package:flutter/material.dart';

import 'pantalla_inicio.dart';
import 'pantalla_perfil_caja.dart';

class ContenedorPrincipal extends StatefulWidget {
  const ContenedorPrincipal({super.key});

  @override
  State<ContenedorPrincipal> createState() => _EstadoContenedorPrincipal();
}

class _EstadoContenedorPrincipal extends State<ContenedorPrincipal> {
  int _indice = 0;

  static final List<Widget> _paginas = <Widget>[
    PantallaInicio(),
    _PantallaProvisional('Tienda / Punto de venta'),
    _PantallaProvisional('Inventario'),
    _PantallaProvisional('Historial de cajas'),
    PantallaPerfilCaja(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _indice, children: _paginas),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _indice,
      onDestinationSelected: (i) => setState(() => _indice = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Tienda',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventario',
        ),
        NavigationDestination(
          icon: Icon(Icons.access_time),
          selectedIcon: Icon(Icons.access_time_filled),
          label: 'Historial',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    ),
  );
}

class _PantallaProvisional extends StatelessWidget {
  final String titulo;
  const _PantallaProvisional(this.titulo);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(titulo)),
    body: Center(child: Text(titulo)),
  );
}
