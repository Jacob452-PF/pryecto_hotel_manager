import 'package:flutter/material.dart';

import 'pantalla_inicio.dart';
import 'tienda/pantalla_tienda.dart';
import 'pantalla_perfil_caja.dart';

class ContenedorPrincipal extends StatefulWidget {
  const ContenedorPrincipal({super.key});

  @override
  State<ContenedorPrincipal> createState() => _EstadoContenedorPrincipal();
}

class _EstadoContenedorPrincipal extends State<ContenedorPrincipal> {
  int _indice = 0;

  static const _paginas = <Widget>[
    PantallaInicio(),
    PantallaTienda(),
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
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Tienda',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventario',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Historial',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: 'Caja',
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
