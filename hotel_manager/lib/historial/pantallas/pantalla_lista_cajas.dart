import 'package:flutter/material.dart';

import '../modelos/periodo_historial.dart';
import '../servicios/servicio_historial.dart';
import '../utilidades/estilos_historial.dart';
import '../widgets/boton_pildora.dart';
import '../widgets/filtros_periodo.dart';
import '../widgets/tarjeta_caja.dart';
import 'pantalla_cierre_caja.dart';
import 'pantalla_detalle_caja.dart';

/// Pantalla "Historial": lista de cierres de caja con búsqueda y filtros.
class PantallaListaCajas extends StatefulWidget {
  const PantallaListaCajas({super.key});

  @override
  State<PantallaListaCajas> createState() => _EstadoPantallaListaCajas();
}

class _EstadoPantallaListaCajas extends State<PantallaListaCajas> {
  static const _vistaPrevia = 3;

  final ServicioHistorial _servicio = ServicioHistorial.instancia;
  final TextEditingController _busqueda = TextEditingController();
  PeriodoHistorial _periodo = PeriodoHistorial.todo;
  bool _verTodas = false;

  @override
  void initState() {
    super.initState();
    _servicio.addListener(_refrescar);
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _servicio.removeListener(_refrescar);
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final texto = _busqueda.text.trim().toLowerCase();

    final cajas = _servicio.cajas.where((c) {
      if (!_periodo.contiene(c.fecha, ahora)) return false;
      if (texto.isEmpty) return true;
      return c.numero.contains(texto) || c.cajero.toLowerCase().contains(texto);
    }).toList();

    final visibles = _verTodas ? cajas : cajas.take(_vistaPrevia).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            // Encabezado
            Row(
              children: [
                const Icon(Icons.history, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Historial',
                        style: TextStyle(
                          fontFamily: fuenteTitulo,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Consulta de gastos y cierres de caja',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Panel blanco
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _busqueda,
                    onChanged: (_) => setState(() => _verTodas = false),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FiltrosPeriodo(
                    seleccionado: _periodo,
                    onCambio: (p) => setState(() {
                      _periodo = p;
                      _verTodas = false;
                    }),
                  ),
                  const SizedBox(height: 14),
                  if (visibles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay cierres de caja en este periodo.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  for (var i = 0; i < visibles.length; i++)
                    TarjetaCaja(
                      caja: visibles[i],
                      destacada: i == 0,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PantallaDetalleCaja(caja: visibles[i]),
                        ),
                      ),
                    ),
                  if (cajas.length > _vistaPrevia)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _verTodas = !_verTodas),
                        child: Text(
                          _verTodas ? 'ver menos' : 'ver todas',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BotonPildora(
        texto: 'Cierre de caja',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => PantallaCierreCaja())),
      ),
    );
  }
}
