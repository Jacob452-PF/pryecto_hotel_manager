import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Muestra la foto del producto y permite tomarla con la cámara.
/// Guarda la foto como bytes, así funciona igual en celular, web y escritorio.
class SelectorFotoProducto extends StatelessWidget {
  final Uint8List? foto;
  final ValueChanged<Uint8List?> onCambio;

  const SelectorFotoProducto({
    super.key,
    required this.foto,
    required this.onCambio,
  });

  Future<void> _elegir(BuildContext context, ImageSource origen) async {
    try {
      final archivo = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (archivo == null) return; // la persona canceló
      onCambio(await archivo.readAsBytes());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo usar la cámara en este dispositivo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _elegir(context, ImageSource.camera),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colores.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colores.outlineVariant),
        ),
        child: foto == null
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 36, color: colores.primary),
                SizedBox(height: 8),
                Text('Agregar foto', style: TextStyle(color: colores.onSurfaceVariant)),
              ],
            )
            : Image.memory(foto!, fit: BoxFit.cover),
      ),
    );
  }
}
