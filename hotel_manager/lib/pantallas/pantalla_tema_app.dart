import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../tema/dimensiones.dart';
import '../tema/estilos_texto.dart';

class PantallaTemaApp extends StatefulWidget {
  const PantallaTemaApp({super.key});

  @override
  State<PantallaTemaApp> createState() => _EstadoPantallaTemaApp();
}

class _EstadoPantallaTemaApp extends State<PantallaTemaApp> {
  int _indicePaleta = 0;

  static const _paletas = <_PaletaTema>[
    _PaletaTema(
      nombre: 'Recepción clásica',
      detalle: 'Azul institucional, limpio y confiable.',
      primario: ColoresApp.primario,
      secundario: Color(0xFF71A7E8),
      fondo: Color(0xFFF5F2FB),
      icono: Icons.business_center,
    ),
    _PaletaTema(
      nombre: 'Noche boutique',
      detalle: 'Oscuro elegante para turnos nocturnos.',
      primario: Color(0xFF253047),
      secundario: Color(0xFFD6B36A),
      fondo: Color(0xFFEEF0F5),
      icono: Icons.nightlight_round,
    ),
    _PaletaTema(
      nombre: 'Jardín del hotel',
      detalle: 'Verde sereno, fresco y hospitalario.',
      primario: Color(0xFF2F6F63),
      secundario: Color(0xFF9AC7A9),
      fondo: Color(0xFFF1F7F2),
      icono: Icons.spa,
    ),
    _PaletaTema(
      nombre: 'Día cálido',
      detalle: 'Amable, luminoso y cercano.',
      primario: Color(0xFF9B4D2E),
      secundario: Color(0xFFF0B45B),
      fondo: Color(0xFFFFF7EC),
      icono: Icons.wb_sunny,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final paleta = _paletas[_indicePaleta];

    return Scaffold(
      backgroundColor: paleta.fondo,
      appBar: AppBar(title: const Text('Tema de la app')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VistaPreviaTema(paleta: paleta),
            const SizedBox(height: 18),
            const Text(
              'Paletas sugeridas',
              style: EstilosTexto.subtituloSeccion,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _paletas.length; i++) ...[
              _OpcionPaleta(
                paleta: _paletas[i],
                seleccionada: i == _indicePaleta,
                alTocar: () => setState(() => _indicePaleta = i),
              ),
              if (i != _paletas.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            _AvisoPendiente(paleta: paleta),
          ],
        ),
      ),
    );
  }
}

class _VistaPreviaTema extends StatelessWidget {
  final _PaletaTema paleta;

  const _VistaPreviaTema({required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: paleta.primario,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(paleta.icono, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paleta.nombre, style: EstilosTexto.tituloSeccion),
                    Text(paleta.detalle, style: EstilosTexto.detalleOpcion),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MuestraColor(color: paleta.primario, etiqueta: 'Principal'),
              const SizedBox(width: 10),
              _MuestraColor(color: paleta.secundario, etiqueta: 'Acento'),
              const SizedBox(width: 10),
              _MuestraColor(color: paleta.fondo, etiqueta: 'Fondo'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: paleta.primario.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
              border: Border.all(
                color: paleta.primario.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.king_bed, color: paleta.primario),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación 204',
                        style: EstilosTexto.etiquetaOpcion,
                      ),
                      Text(
                        'Disponible · piso 2',
                        style: EstilosTexto.detalleOpcion,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: paleta.secundario,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Lista',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionPaleta extends StatelessWidget {
  final _PaletaTema paleta;
  final bool seleccionada;
  final VoidCallback alTocar;

  const _OpcionPaleta({
    required this.paleta,
    required this.seleccionada,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: seleccionada ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        side: BorderSide(
          color: seleccionada ? paleta.primario : Colors.transparent,
          width: seleccionada ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _PuntosPaleta(paleta: paleta),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paleta.nombre, style: EstilosTexto.tituloTarjeta),
                    const SizedBox(height: 2),
                    Text(paleta.detalle, style: EstilosTexto.detalleOpcion),
                  ],
                ),
              ),
              Icon(
                seleccionada
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: seleccionada
                    ? paleta.primario
                    : ColoresApp.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoPendiente extends StatelessWidget {
  final _PaletaTema paleta;

  const _AvisoPendiente({required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.advertencia.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        border: Border.all(
          color: ColoresApp.advertencia.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction, color: ColoresApp.advertencia),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta vista deja preparado el estilo visual. La aplicación del tema '
              '${paleta.nombre.toLowerCase()} se conectará cuando el resto de la app esté completo.',
              style: EstilosTexto.detalleFactura.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuestraColor extends StatelessWidget {
  final Color color;
  final String etiqueta;

  const _MuestraColor({required this.color, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(etiqueta, style: EstilosTexto.detalleOpcion),
        ],
      ),
    );
  }
}

class _PuntosPaleta extends StatelessWidget {
  final _PaletaTema paleta;

  const _PuntosPaleta({required this.paleta});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Stack(
        children: [
          _PuntoColor(color: paleta.fondo, izquierda: 0),
          _PuntoColor(color: paleta.secundario, izquierda: 14),
          _PuntoColor(color: paleta.primario, izquierda: 28),
        ],
      ),
    );
  }
}

class _PuntoColor extends StatelessWidget {
  final Color color;
  final double izquierda;

  const _PuntoColor({required this.color, required this.izquierda});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: izquierda,
      top: 0,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _PaletaTema {
  final String nombre;
  final String detalle;
  final Color primario;
  final Color secundario;
  final Color fondo;
  final IconData icono;

  const _PaletaTema({
    required this.nombre,
    required this.detalle,
    required this.primario,
    required this.secundario,
    required this.fondo,
    required this.icono,
  });
}
