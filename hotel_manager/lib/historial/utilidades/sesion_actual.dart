import '../../servicios/servicio_sesion.dart';

/// Nombre del usuario que tiene la sesión abierta (el cajero).
/// Es el único lugar del historial que lee `ServicioSesion`: si el campo del
/// nombre en `Usuario` se llama distinto a `nombre`, solo hay que cambiarlo aquí.
String nombreUsuarioActual() {
  final usuario = ServicioSesion.instancia.usuario;
  return usuario?.nombre ?? 'Sin sesión';
}
