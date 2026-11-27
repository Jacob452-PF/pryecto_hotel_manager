import 'package:flutter/material.dart';

class _Guia {
  final IconData icono;
  final String titulo;
  final String resumen;
  final List<String> pasos;

  const _Guia(this.icono, this.titulo, this.resumen, this.pasos);
}

class PantallaTutorial extends StatelessWidget {
  const PantallaTutorial({super.key});

  static const _guias = <_Guia>[
    _Guia(Icons.login, '1. Entrar a la aplicación',
        'Usa la cuenta que te asignó el administrador.', [
      'Escribe tu correo y contraseña en la pantalla de acceso.',
      'Pulsa “Iniciar sesión”. Si los datos no son válidos, revisa que no haya espacios y vuelve a intentarlo.',
      'La aplicación muestra las secciones habilitadas para tu cargo. Limpieza y mantenimiento entran directamente a sus tareas.',
    ]),
    _Guia(Icons.point_of_sale, '2. Abrir el turno de caja',
        'Recepción y administración pueden registrar el fondo inicial.', [
      'Al iniciar el turno, abre “Abrir caja” cuando la aplicación lo solicite o desde Perfil.',
      'Cuenta el efectivo disponible e ingresa el fondo inicial en billetes y monedas.',
      'Confirma la apertura. Mantén el turno abierto mientras registras movimientos de caja.',
    ]),
    _Guia(Icons.calendar_month, '3. Crear una reserva',
        'Registra los datos del huésped y el período de la estadía.', [
      'Entra en “Agenda” y elige el día de llegada de la reserva.',
      'Pulsa el botón para crear una reserva y completa los datos requeridos del huésped.',
      'Selecciona la tarifa, las fechas y la habitación si el flujo la solicita; revisa los datos antes de guardar.',
      'La reserva aparece en la agenda para su fecha. Puedes volver a abrirla para consultar sus datos y registrar abonos o el check-in.',
    ]),
    _Guia(Icons.hotel, '4. Registrar una entrada y estadía',
        'Desde recepción se asigna una habitación y comienza la estadía.', [
      'En “Inicio” consulta el estado de las habitaciones o abre “Agenda” para localizar la reserva.',
      'Abre la habitación disponible o la reserva correspondiente y confirma los datos de entrada.',
      'Registra al huésped cuando el flujo lo requiera y confirma el check-in para iniciar la estadía.',
      'La habitación ocupada deja de aparecer como disponible. Los cargos asociados se consultan desde la estadía y el historial.',
    ]),
    _Guia(Icons.cleaning_services, '5. Atender limpieza',
        'Las habitaciones en limpieza no se pueden asignar hasta completar la tarea.', [
      'Al terminar una estadía, la habitación pasa al estado “En limpieza” y se genera o solicita la tarea correspondiente.',
      'La persona de limpieza abre “Tareas” y revisa las habitaciones asignadas. También puede consultar las habitaciones que requieren limpieza.',
      'Abre la tarea para ver la habitación y sus detalles.',
      'Cuando el trabajo esté completo, marca la tarea como finalizada. La habitación puede volver a estar disponible si no tiene otro bloqueo.',
    ]),
    _Guia(Icons.storefront, '6. Registrar ventas y consumos',
        'La tienda registra productos vendidos durante el turno.', [
      'Abre “Tienda” y agrega los artículos indicando la cantidad.',
      'Si corresponde a una estadía, selecciona la habitación o huésped para asociar el consumo.',
      'Revisa el total, el método de pago y confirma la venta. Las ventas quedan reflejadas en el historial y pueden actualizar existencias.',
    ]),
    _Guia(Icons.inventory_2, '7. Consultar inventario',
        'Revisa productos, existencias y movimientos disponibles para tu cargo.', [
      'Abre “Inventario” desde la barra inferior.',
      'Busca el producto y consulta la cantidad disponible y sus movimientos.',
      'Usa las opciones de registro de compra o ajuste solo si están habilitadas para tu cuenta; revisa cantidades y costos antes de guardar.',
    ]),
    _Guia(Icons.history, '8. Revisar historial y cerrar caja',
        'Antes de terminar el turno, compara los movimientos y registra el cierre.', [
      'Entra a “Historial” para revisar ventas y gastos del turno.',
      'Comprueba que los movimientos y montos coincidan con lo recibido y pagado.',
      'Desde “Perfil” o “Historial”, selecciona “Cerrar caja”, registra el efectivo contado y confirma el cierre.',
      'Si hay diferencias, verifica los movimientos del turno antes de confirmar.',
    ]),
    _Guia(Icons.notifications_active_outlined, '9. Avisos y conexión',
        'La campana y el indicador de conexión ayudan a detectar pendientes.', [
      'Pulsa la campana para revisar avisos de reservas, estadías, habitaciones o inventario.',
      'Pulsa “Ver” en un aviso para abrir su detalle cuando esté disponible.',
      'Si aparece un aviso de conexión, espera a que vuelva el servicio y revisa que la información se haya sincronizado antes de repetir una operación.',
    ]),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tutorial paso a paso')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Guía de uso',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Text(
            'Abre cada sección para ver los pasos. Algunas opciones dependen de tu cargo y pueden no aparecer en tu cuenta.',
          ),
        ),
        for (final guia in _guias)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: CircleAvatar(child: Icon(guia.icono)),
              title: Text(guia.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(guia.resumen),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              children: [
                for (var i = 0; i < guia.pasos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text('${i + 1}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(guia.pasos[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
