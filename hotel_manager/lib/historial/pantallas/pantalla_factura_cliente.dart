import 'package:flutter/material.dart';

import '../../utilidades/formato.dart' as global;
import '../modelos/consumo_cliente.dart';
import '../modelos/turno_caja.dart';
import '../utilidades/estilos_historial.dart';
import '../utilidades/formato.dart';

/// Factura completa de un cliente: sus datos, la habitación, todo lo que se
/// le cobró y quién lo registró. Se abre desde "Ver factura completa".
class PantallaFacturaCliente extends StatelessWidget {
  final ConsumoCliente consumo;
  const PantallaFacturaCliente({super.key, required this.consumo});

  String _descripcion(LineaConsumo l) {
    final f = consumo.factura;
    if (f != null && l.tipo == TipoVenta.habitaciones) {
      final camas = f.habitacion.camas;
      return 'Estadía ($camas ${camas == 1 ? 'cama' : 'camas'}): '
          '${l.cantidad} ${f.tarifa.unidad(l.cantidad)} × ${dinero(l.precio)}';
    }
    return l.cantidad > 1 ? '${l.nombre} × ${l.cantidad}' : l.nombre;
  }

  @override
  Widget build(BuildContext context) {
    final f = consumo.factura;

    return Scaffold(
      backgroundColor: ColoresHistorial.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Volver',
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Factura del cliente',
                        style: TextStyle(
                          fontFamily: fuenteTitulo,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Encabezado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColoresHistorial.azulClaro,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColoresHistorial.borde),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f == null
                                  ? consumo.cliente
                                  : 'Hab. ${f.habitacion.numero} · ${consumo.cliente}',
                              style: const TextStyle(
                                fontFamily: fuenteTitulo,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            dinero(consumo.total),
                            style: const TextStyle(
                              fontFamily: fuenteTitulo,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (f != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          fechaHora(f.fecha),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (consumo.registradoPor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Registrado por: ${consumo.registradoPor}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (f == null)
                  const _Seccion(
                    icono: Icons.info_outline,
                    titulo: 'Datos del huésped',
                    hijos: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Este cliente no tiene los datos del registro guardados.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _Seccion(
                    icono: Icons.person,
                    titulo: 'Huésped',
                    hijos: [
                      _Dato(Icons.badge_outlined, 'Nombre', f.huesped),
                      _Dato(
                        Icons.credit_card,
                        'DUI',
                        global.formatearDui(f.dui),
                      ),
                      _Dato(
                        Icons.phone,
                        'Teléfono',
                        global.formatearTelefono(f.telefono),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Seccion(
                    icono: Icons.door_front_door,
                    titulo: 'Habitación',
                    hijos: [
                      _Dato(
                        Icons.meeting_room,
                        'Número',
                        '${f.habitacion.numero} (piso ${f.habitacion.piso})',
                      ),
                      _Dato(
                        f.habitacion.tipoCuarto.icono,
                        'Tipo',
                        f.habitacion.tipoCuarto.etiqueta,
                      ),
                      _Dato(
                        Icons.bed,
                        'Camas',
                        '${f.habitacion.camas} ${f.habitacion.camas == 1 ? 'cama' : 'camas'}',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _Seccion(
                  icono: Icons.receipt_long,
                  titulo: 'Detalle de la factura',
                  hijos: [
                    for (final l in consumo.lineas)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _descripcion(l),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dinero(l.importe),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          dinero(consumo.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final List<Widget> hijos;

  const _Seccion({
    required this.icono,
    required this.titulo,
    required this.hijos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresHistorial.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: fuenteTitulo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...hijos,
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Dato(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              etiqueta,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
