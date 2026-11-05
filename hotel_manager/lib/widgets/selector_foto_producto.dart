import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Muestra la foto del producto y deja tomarla con la cámara o subirla de la galería.
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
            'No se pudo usar la cámara en este dispositivo. Prueba con la galería.',
          ),
        ),
      );
    }
  }

  void _abrirMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _elegir(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _elegir(context, ImageSource.gallery);
              },
            ),
            if (foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCambio(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _abrirMenu(context),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 160,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: foto == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 36),
                SizedBox(height: 8),
                Text('Agregar foto'),
              ],
            )
          : Image.memory(foto!, fit: BoxFit.cover),
    ),
  );
}
