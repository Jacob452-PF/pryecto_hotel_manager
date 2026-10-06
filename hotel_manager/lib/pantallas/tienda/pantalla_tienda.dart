import 'package:flutter/material.dart';

import 'producto_tienda.dart';

class PantallaTienda extends StatefulWidget {
  const PantallaTienda({super.key});

  @override
  State<PantallaTienda> createState() => _EstadoPantallaTienda();
}

class _EstadoPantallaTienda extends State<PantallaTienda> {
  static const _fondo = Color(0xFFF3F0FA);
  static const _gris = Color(0xFFD9D9D9);

  static const _categorias = <(String, IconData)>[
    ('Todos', Icons.grid_view_rounded),
    ('Alimentos', Icons.restaurant),
    ('Bebidas', Icons.wine_bar),
    ('Aseo', Icons.cleaning_services),
    ('Lencería', Icons.bed),
    ('Otros', Icons.more_horiz),
  ];

  static const _secciones = <(String, IconData)>[
    ('Habitaciones', Icons.bed_outlined),
    ('Servicio', Icons.room_service_outlined),
    ('Productos del hotel', Icons.shopping_bag_outlined),
  ];

  String _categoria = 'Todos';
  String _busqueda = '';
  final Map<String, int> _carrito = {}; // id -> cantidad

  int get _totalItems => _carrito.values.fold(0, (a, b) => a + b);

  double get _totalPrecio => _carrito.entries.fold(
    0.0,
    (suma, e) =>
        suma + productosDemo.firstWhere((p) => p.id == e.key).precio * e.value,
  );

  void _agregar(ProductoTienda p) =>
      setState(() => _carrito[p.id] = (_carrito[p.id] ?? 0) + 1);

  void _quitar(ProductoTienda p) => setState(() {
    final n = (_carrito[p.id] ?? 0) - 1;
    n <= 0 ? _carrito.remove(p.id) : _carrito[p.id] = n;
  });

  List<ProductoTienda> _filtrados(String seccion) => productosDemo
      .where(
        (p) =>
            p.seccion == seccion &&
            (_categoria == 'Todos' || p.categoria == _categoria) &&
            p.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final secciones = _secciones
        .where((s) => _filtrados(s.$1).isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              _encabezado(),
              const SizedBox(height: 12),
              _panelBusqueda(),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: secciones.isEmpty
                      ? const Center(
                          child: Text('No hay productos con ese filtro'),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            for (final s in secciones) _seccion(s.$1, s.$2),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _encabezado() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Tienda',
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      ),
      Badge(
        isLabelVisible: _totalItems > 0,
        label: Text('$_totalItems'),
        child: InkWell(
          onTap: _abrirCarrito,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF35D0F0), Color(0xFF3B8BF5)],
              ),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _panelBusqueda() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: InputDecoration(
            hintText: 'Search',
            isDense: true,
            suffixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (nombre, icono) = _categorias[i];
              final activa = nombre == _categoria;
              return InkWell(
                onTap: () => setState(() => _categoria = nombre),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 66,
                  decoration: BoxDecoration(
                    color: activa ? const Color(0xFFBFD7FF) : _gris,
                    borderRadius: BorderRadius.circular(10),
                    border: activa
                        ? Border.all(color: const Color(0xFF3B8BF5), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, size: 22),
                      const SizedBox(height: 4),
                      Text(nombre, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _seccion(String titulo, IconData icono) {
    final items = _filtrados(titulo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 168,
            ),
            itemBuilder: (_, i) => _tarjeta(items[i]),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(ProductoTienda p) {
    final cantidad = _carrito[p.id] ?? 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aquí luego puedes poner Image.asset / Image.network
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _gris,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${p.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () => _agregar(p),
                customBorder: const CircleBorder(),
                child: cantidad == 0
                    ? const Icon(Icons.add_circle_outline, size: 26)
                    : CircleAvatar(
                        radius: 13,
                        backgroundColor: const Color(0xFF3B8BF5),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          final lineas = _carrito.entries.toList();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Carrito',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (lineas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aún no agregas productos'),
                  )
                else
                  for (final e in lineas)
                    Builder(
                      builder: (_) {
                        final p = productosDemo.firstWhere(
                          (x) => x.id == e.key,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.nombre),
                          subtitle: Text(
                            '\$${p.precio.toStringAsFixed(2)} c/u',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  _quitar(p);
                                  setSheet(() {});
                                },
                              ),
                              Text('${e.value}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  _agregar(p);
                                  setSheet(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${_totalPrecio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: lineas.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                          ), // TODO: cobrar / cargar a habitación
                    child: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
