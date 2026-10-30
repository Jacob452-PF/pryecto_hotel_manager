import '../modelos/configuracion_hotel.dart';

/// Integración de salida en modo local. TODO(API): conectar proveedor WhatsApp/correo.
class AvisoExternoService {
  const AvisoExternoService();

  Future<void> enviar({
    required String destino,
    required String mensaje,
    required CanalAvisoHuesped canal,
  }) async {
    // TODO(API): enviar por el proveedor correspondiente cuando exista backend.
    // ignore: avoid_print
    print('Aviso externo stub [$canal] a $destino: $mensaje');
  }
}
