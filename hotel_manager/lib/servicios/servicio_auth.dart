import '../modelos/usuario.dart';
import 'api_client.dart';

/// Los usuarios operativos se consultan al backend; no se crean cuentas seed.
class ServicioAuth {
  ServicioAuth._();
  static final instancia = ServicioAuth._();

  Future<List<Usuario>> usuarios() async {
    final recibidos = <Usuario>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await ApiClient.instance.users(page: page);
      final rows = ApiClient.instance.listFromResponse(response);
      recibidos.addAll(rows.map((row) => Usuario.fromApiJson(
            Map<String, dynamic>.from(row as Map),
          )));
      if (response is Map) {
        final meta = response['meta'];
        lastPage = int.tryParse(
              (response['last_page'] ?? (meta is Map ? meta['last_page'] : null))
                      ?.toString() ??
                  '',
            ) ??
            page;
      }
      page++;
    } while (page <= lastPage);
    return recibidos;
  }
}
