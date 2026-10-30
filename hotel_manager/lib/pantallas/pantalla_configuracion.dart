import 'package:flutter/material.dart';

import '../modelos/configuracion_hotel.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_configuracion.dart';
import '../servicios/servicio_sesion.dart';

class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    if (ServicioSesion.instancia.usuario?.rol != RolUsuario.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: const Center(
          child: Text('Solo administración puede editar la configuración.'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: ServicioConfiguracion.instancia,
      builder: (context, _) {
        final servicio = ServicioConfiguracion.instancia;
        final c = servicio.valor;
        Future<void> actualizar(ConfiguracionHotel n) => servicio.actualizar(n);
        Widget campoNumero(
          String titulo,
          int valor,
          ConfiguracionHotel Function(int) cambiar,
        ) => ListTile(
          title: Text(titulo),
          trailing: SizedBox(
            width: 100,
            child: TextFormField(
              key: ValueKey('$titulo-$valor'),
              initialValue: '$valor',
              keyboardType: TextInputType.number,
              onFieldSubmitted: (s) {
                final n = int.tryParse(s);
                if (n != null && n >= 0) actualizar(cambiar(n));
              },
            ),
          ),
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Configuración')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              campoNumero(
                'Tolerancia de reserva (horas)',
                c.toleranciaVencimientoReservaHoras,
                (n) => c.copyWith(toleranciaVencimientoReservaHoras: n),
              ),
              campoNumero(
                'Margen de limpieza (horas)',
                c.margenDesocupacionLimpiezaHoras,
                (n) => c.copyWith(margenDesocupacionLimpiezaHoras: n),
              ),
              campoNumero(
                'Tolerancia de check-out (min)',
                c.toleranciaCheckoutMin,
                (n) => c.copyWith(toleranciaCheckoutMin: n),
              ),
              campoNumero(
                'Repetición de aviso (min)',
                c.repeticionAvisoEstadiaMin,
                (n) => c.copyWith(repeticionAvisoEstadiaMin: n),
              ),
              ListTile(
                title: const Text('Canal de aviso al huésped'),
                trailing: DropdownButton<CanalAvisoHuesped>(
                  value: c.canalAvisoHuesped,
                  items: CanalAvisoHuesped.values
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) actualizar(c.copyWith(canalAvisoHuesped: v));
                  },
                ),
              ),
              TextFormField(
                initialValue: c.plantillaMensajeVencimiento,
                decoration: const InputDecoration(
                  labelText: 'Plantilla de mensaje de vencimiento',
                ),
                onFieldSubmitted: (v) =>
                    actualizar(c.copyWith(plantillaMensajeVencimiento: v)),
              ),
              ListTile(
                title: const Text('Margen de ganancia de producto'),
                subtitle: Text('${(c.margenGananciaProducto * 100).round()}%'),
                trailing: DropdownButton<double>(
                  value: c.margenGananciaProducto,
                  items: const [
                    DropdownMenuItem(value: .2, child: Text('+20%')),
                    DropdownMenuItem(value: .3, child: Text('+30%')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      actualizar(c.copyWith(margenGananciaProducto: v));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
