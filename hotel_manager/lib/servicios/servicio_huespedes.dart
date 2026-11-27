import 'package:flutter/foundation.dart';

import '../modelos/huesped.dart';
import 'api_client.dart';

/// Huéspedes recibidos de la API. El storage local anterior se conserva en el
/// dispositivo, pero no se mezcla con la lista del servidor.
class ServicioHuespedes extends ChangeNotifier {
  ServicioHuespedes._();
  static final instancia = ServicioHuespedes._();

  final List<Huesped> _huespedes = [];
  List<Huesped> get huespedes => List.unmodifiable(_huespedes);
  bool cargando = false;
  String? error;
  bool _sincronizacionEnCurso = false;

  Huesped? porDui(String dui) {
    final clave = _normalizar(dui);
    for (final huesped in _huespedes) {
      if (_normalizar(huesped.dui) == clave) return huesped;
    }
    return null;
  }

  String _normalizar(String documento) =>
      documento.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

  Future<void> cargar() => sincronizar();

  Future<void> sincronizar({String? busqueda}) async {
    if (_sincronizacionEnCurso) return;
    _sincronizacionEnCurso = true;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      const porPagina = 100;
      final recibidos = <Huesped>[];
      var pagina = 1;
      var paginas = 1;
      do {
        final respuesta = await ApiClient.instance.guests(
          page: pagina,
          perPage: porPagina,
          query: busqueda,
        );
        final filas = ApiClient.instance.listFromResponse(respuesta);
        recibidos.addAll(
          filas.map(
            (fila) =>
                Huesped.fromApiJson(Map<String, dynamic>.from(fila as Map)),
          ),
        );
        if (respuesta is Map) {
          final meta = respuesta['meta'];
          final rawLastPage =
              respuesta['last_page'] ??
              (meta is Map ? meta['last_page'] : null);
          paginas =
              int.tryParse(rawLastPage?.toString() ?? '') ??
              (filas.length == porPagina ? pagina + 1 : pagina);
        }
        pagina++;
      } while (pagina <= paginas);

      _huespedes
        ..clear()
        ..addAll(recibidos);
    } on ApiException catch (e) {
      error = e.message;
    } on FormatException catch (e) {
      error =
          'La respuesta de huéspedes no tiene el formato esperado: ${e.message}';
    } catch (_) {
      error = 'No se pudieron cargar los huéspedes desde el servidor.';
    } finally {
      cargando = false;
      _sincronizacionEnCurso = false;
      notifyListeners();
    }
  }

  /// Busca primero por documento en el servidor para evitar duplicados aunque
  /// el huésped no esté en la página cargada actualmente.
  Future<Huesped> obtenerOCrear({
    required String nombre,
    required String dui,
    required String telefono,
    String? email,
  }) async {
    final documento = _normalizar(dui);
    if (documento.isEmpty) throw ArgumentError('El DUI es obligatorio.');

    final existente = porDui(documento);
    if (existente != null) return existente;

    final respuestaBusqueda = await ApiClient.instance.guests(
      query: dui.trim(),
      perPage: 100,
    );
    final filas = ApiClient.instance.listFromResponse(respuestaBusqueda);
    for (final fila in filas) {
      final encontrado = Huesped.fromApiJson(
        Map<String, dynamic>.from(fila as Map),
      );
      if (_normalizar(encontrado.dui) == documento) {
        _agregarSiFalta(encontrado);
        return encontrado;
      }
    }

    final creado = await ApiClient.instance.createGuest({
      'name': nombre.trim(),
      'document': dui.trim(),
      'phone': telefono.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
    final mapa = _desenvolverGuest(creado);
    final huesped = Huesped.fromApiJson(mapa);
    _agregarSiFalta(huesped);
    return huesped;
  }

  /// Completa datos obligatorios que falten en un huésped seleccionado para
  /// poder asociarlo a una reserva sin crear un registro duplicado.
  Future<Huesped> completarDatosReserva(
    Huesped huesped, {
    required String nombre,
    required String dui,
    required String telefono,
  }) async {
    final cambios = <String, dynamic>{};
    if (huesped.nombre.trim().isEmpty && nombre.trim().isNotEmpty) {
      cambios['name'] = nombre.trim();
    }
    if (huesped.dui.trim().isEmpty && dui.trim().isNotEmpty) {
      cambios['document'] = dui.trim();
    }
    if (huesped.telefono.trim().isEmpty && telefono.trim().isNotEmpty) {
      cambios['phone'] = telefono.trim();
    }
    if (cambios.isEmpty) return huesped;

    final response = await ApiClient.instance.updateGuest(
      huesped.id,
      cambios,
      partial: true,
    );
    final actualizado = Huesped.fromApiJson(_desenvolverGuest(response));
    _agregarSiFalta(actualizado);
    return actualizado;
  }

  Map<String, dynamic> _desenvolverGuest(dynamic response) {
    if (response is! Map) {
      throw const FormatException('El servidor no devolvió el huésped creado.');
    }
    dynamic guest = response['guest'] ?? response['data'] ?? response;
    if (guest is Map && guest['data'] is Map) guest = guest['data'];
    if (guest is! Map) {
      throw const FormatException('El servidor no devolvió el huésped creado.');
    }
    return Map<String, dynamic>.from(guest);
  }

  void _agregarSiFalta(Huesped huesped) {
    final indice = _huespedes.indexWhere((h) => h.id == huesped.id);
    if (indice < 0) {
      _huespedes.add(huesped);
    } else {
      _huespedes[indice] = huesped;
    }
    error = null;
    notifyListeners();
  }
}
