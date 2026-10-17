import 'package:flutter/material.dart';

import '../servicios/servicio_tema.dart';
import '../tema/dimensiones.dart';
import '../tema/paletas_tema.dart';

/// Selector de apariencia disponible desde Perfil.
class PantallaTema extends StatelessWidget {
  const PantallaTema({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicioTema.instancia,
      builder: (context, _) {
        final actual = ServicioTema.instancia.paleta;
        final tema = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Tema de la app')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Personaliza el ambiente de Hotel Manager. El cambio se aplica en todas las pantallas y se guarda automáticamente.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _VistaPrevia(paleta: actual),
              const SizedBox(height: 22),
              Text('Temas disponibles', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              for (final paleta in PaletasTema.todas) ...[
                _OpcionTema(
                  paleta: paleta,
                  seleccionada: actual.nombre == paleta.nombre,
                  alTocar: () => ServicioTema.instancia.elegir(paleta),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final PaletaTema paleta;
  const _VistaPrevia({required this.paleta});

  @override
  Widget build(BuildContext context) {
    final texto = paleta.texto;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: paleta.superficie,
        borderRadius: BorderRadius.circular(Dimensiones.radioGrande),
        border: Border.all(color: paleta.color.withValues(alpha: 0.16)),
        boxShadow: [BoxShadow(color: paleta.color.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [paleta.color, paleta.acento]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(paleta.icono, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paleta.nombre, style: TextStyle(color: texto, fontSize: 17, fontWeight: FontWeight.w700)),
            Text(paleta.detalle, style: TextStyle(color: paleta.textoSecundario, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: paleta.superficieSuave,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: paleta.color.withValues(alpha: 0.10)),
          ),
          child: Row(children: [
            Icon(Icons.king_bed_outlined, color: paleta.color),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Habitación 204', style: TextStyle(color: texto, fontWeight: FontWeight.w700)),
              Text('Disponible · piso 2', style: TextStyle(color: paleta.textoSecundario, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: paleta.color, borderRadius: BorderRadius.circular(99)),
              child: const Text('Lista', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _BotonMuestra(color: paleta.color, texto: 'Acción principal')),
          const SizedBox(width: 9),
          Expanded(child: _BotonMuestra(color: paleta.acento, texto: 'Acento')),
        ]),
      ]),
    );
  }
}

class _BotonMuestra extends StatelessWidget {
  final Color color;
  final String texto;
  const _BotonMuestra({required this.color, required this.texto});
  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 7),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _OpcionTema extends StatelessWidget {
  final PaletaTema paleta;
  final bool seleccionada;
  final VoidCallback alTocar;
  const _OpcionTema({required this.paleta, required this.seleccionada, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: EdgeInsets.zero,
      elevation: seleccionada ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        side: BorderSide(color: seleccionada ? paleta.color : Theme.of(context).dividerColor, width: seleccionada ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensiones.radioTarjeta),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [paleta.color, paleta.acento]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(paleta.icono, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(paleta.nombre, style: TextStyle(color: texto, fontWeight: FontWeight.w700)),
              Text(paleta.detalle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            Icon(seleccionada ? Icons.check_circle : Icons.circle_outlined, color: seleccionada ? paleta.color : Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
