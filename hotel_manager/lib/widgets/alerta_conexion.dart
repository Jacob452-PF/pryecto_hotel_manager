import 'package:flutter/material.dart';

import '../servicios/servicio_conexion.dart';

class AlertaConexion extends StatelessWidget {
  const AlertaConexion({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ServicioConexion.instancia,
    builder: (context, _) {
      final conexion = ServicioConexion.instancia;
      if (!conexion.sinConexion) return const SizedBox.shrink();
      final colores = Theme.of(context).colorScheme;
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: .68),
          child: PopScope(
            canPop: false,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: .92,
                heightFactor: .52,
                child: Card(
                  color: colores.surface,
                  elevation: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: colores.error,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Se perdió la conexión',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Revisa internet o la conexión con el servidor. La sesión sigue abierta; la app volverá a comprobar automáticamente.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: conexion.verificando
                              ? null
                              : conexion.verificar,
                          icon: conexion.verificando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            conexion.verificando
                                ? 'Comprobando…'
                                : 'Reintentar conexión',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
