import 'package:flutter/material.dart';

const azulDialogo = Color(0xFF3B82F6);

/// Ventana centrada con icono azul y título (usada para "Ajustar producto"
/// y "Agregar producto"). El contenido va en [child].
class DialogoInventario extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Widget child;

  const DialogoInventario({
    super.key,
    required this.icono,
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: azulDialogo,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icono, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B33),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Botones de abajo: "Cancelar" y el botón azul de guardar.
class BotonesDialogo extends StatelessWidget {
  final String textoGuardar;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  const BotonesDialogo({
    super.key,
    required this.textoGuardar,
    required this.onGuardar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelar,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFEDEDF0),
              foregroundColor: const Color(0xFF55555F),
              side: const BorderSide(color: Color(0xFF9A9AA5)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: forma,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onGuardar,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              textoGuardar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: azulDialogo,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: forma,
            ),
          ),
        ),
      ],
    );
  }
}
