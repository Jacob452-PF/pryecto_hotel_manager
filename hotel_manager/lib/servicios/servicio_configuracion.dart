import 'package:flutter/foundation.dart';

import '../modelos/configuracion_hotel.dart';
import 'servicio_storage.dart';

class ServicioConfiguracion extends ChangeNotifier {
  ServicioConfiguracion._();
  static final instancia = ServicioConfiguracion._();
  ConfiguracionHotel _valor = const ConfiguracionHotel();
  ConfiguracionHotel get valor => _valor;

  Future<void> cargar() async {
    final json = await ServicioStorage.instancia.leerObjeto('hotel.config');
    if (json != null) _valor = ConfiguracionHotel.fromJson(json);
  }

  Future<void> actualizar(ConfiguracionHotel nuevo) async {
    _valor = nuevo;
    await ServicioStorage.instancia.guardarObjeto(
      'hotel.config',
      nuevo.toJson(),
    );
    notifyListeners();
  }
}
