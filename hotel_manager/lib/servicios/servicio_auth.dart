import '../modelos/usuario.dart';
import 'servicio_storage.dart';

/// Autenticación local de demostración. TODO(API): autenticación backend y tokens.
class ServicioAuth {
  ServicioAuth._();
  static final instancia = ServicioAuth._();
  static const _clave = 'hotel.usuarios';
  static const contrasenaSeed = 'Hotel123!';

  // Hash determinista simple para el stub local, no apto para credenciales reales.
  String _hash(String input) {
    var h = 0x811c9dc5;
    for (final b in input.codeUnits) {
      h = ((h ^ b) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  Future<List<Usuario>> usuarios() async {
    var data = await ServicioStorage.instancia.leerLista(_clave);
    if (data.isEmpty) {
      final seeds = [
        _seed(
          'u-admin',
          'Administración de prueba',
          '00000000-0',
          'admin01',
          RolUsuario.admin,
        ),
        _seed(
          'u-recep',
          'Recepción de prueba',
          '11111111-1',
          'recep01',
          RolUsuario.recepcion,
        ),
        _seed(
          'u-limp',
          'Limpieza de prueba',
          '22222222-2',
          'limp01',
          RolUsuario.limpieza,
        ),
        _seed(
          'u-mant',
          'Mantenimiento de prueba',
          '33333333-3',
          'mant01',
          RolUsuario.mantenimiento,
        ),
      ];
      await ServicioStorage.instancia.guardarLista(
        _clave,
        seeds.map((u) => u.toJson()).toList(),
      );
      data = await ServicioStorage.instancia.leerLista(_clave);
    }
    return data.map(Usuario.fromJson).toList();
  }

  Usuario _seed(
    String id,
    String nombre,
    String dui,
    String username,
    RolUsuario rol,
  ) => Usuario(
    id: id,
    nombre: nombre,
    dui: dui,
    telefono: '0000-0000',
    username: username,
    rol: rol,
    cargo: switch (rol) {
      RolUsuario.admin => 'Administrador',
      RolUsuario.recepcion => 'Recepción',
      RolUsuario.limpieza => 'Limpieza',
      RolUsuario.mantenimiento => 'Mantenimiento',
    },
    passwordHash: _hash(contrasenaSeed),
  );

  Future<Usuario?> iniciarSesion(String username, String password) async {
    final usuarios = await this.usuarios();
    for (final user in usuarios) {
      if (user.activo &&
          user.username == username.trim() &&
          user.passwordHash == _hash(password)) {
        return user;
      }
    }
    return null;
  }
}
