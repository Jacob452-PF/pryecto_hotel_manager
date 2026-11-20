import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// URL base de la API (Render). Si algún día cambia, se cambia solo aquí.
const String kApiBase = 'https://hotel-manager-api-ttg7.onrender.com/api';

/// La API manda algunos números como texto ("1.50"). Esto los convierte a double.
double toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

/// Error con el mensaje que devuelve la API (o uno de conexión).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final int minStock;
  final String? category;

  Product.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        name = j['name'] as String,
        price = toDouble(j['price']),
        stock = j['stock'] as int,
        minStock = (j['min_stock'] ?? 0) as int,
        category = (j['category'] as Map?)?['name'] as String?;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'auth_token';

  // Render y Aiven se duermen por inactividad: la primera petición puede
  // tardar cerca de un minuto, por eso el timeout es largo.
  static const _timeout = Duration(seconds: 90);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Se ejecuta cuando la API responde 401 (token vencido o inválido).
  /// Úsalo para mandar al usuario de vuelta al login.
  void Function()? onUnauthorized;

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> _saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ---------------------------------------------------------------------------
  // Petición base
  // ---------------------------------------------------------------------------
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$kApiBase$path');
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final payload = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      if (method == 'POST') {
        res = await http
            .post(uri, headers: headers, body: payload)
            .timeout(_timeout);
      } else if (method == 'PUT') {
        res = await http
            .put(uri, headers: headers, body: payload)
            .timeout(_timeout);
      } else {
        res = await http.get(uri, headers: headers).timeout(_timeout);
      }
    } on TimeoutException {
      throw ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (_) {
      throw ApiException(
          'No se pudo conectar con el servidor. Revisa tu conexión a internet.');
    }

    // La API responde con Content-Type: text/html, por eso el JSON se
    // decodifica a mano y no se depende de que el cliente lo haga solo.
    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode == 401 && path != '/login') {
      await clearToken();
      onUnauthorized?.call();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(data, res.statusCode), res.statusCode);
    }
    return data;
  }

  String _errorMessage(dynamic data, int status) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return 'Error $status';
  }

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);
  List<dynamic> _list(dynamic v) => List<dynamic>.from(v as List);

  // ---------------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------------

  /// Inicia sesión, guarda el token y devuelve los datos del usuario
  /// ({id, name, email, role}).
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _request('POST', '/login',
        body: {'email': email, 'password': password});
    await _saveToken(data['token'] as String);
    return _map(data['user']);
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } catch (_) {
      // Aunque falle, se cierra la sesión del lado del teléfono.
    }
    await clearToken();
  }

  Future<Map<String, dynamic>> me() async => _map(await _request('GET', '/me'));

  // ---------------------------------------------------------------------------
  // Catálogo
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> categories() async =>
      _list(await _request('GET', '/categories'));

  Future<List<Product>> products({String? search}) async {
    final qs = (search != null && search.isNotEmpty)
        ? '?q=${Uri.encodeQueryComponent(search)}'
        : '';
    final list = _list(await _request('GET', '/products$qs'));
    return list.map((e) => Product.fromJson(_map(e))).toList();
  }

  // ---------------------------------------------------------------------------
  // Turnos y cierre de caja
  // ---------------------------------------------------------------------------

  /// Devuelve el turno abierto del usuario, o null si no tiene ninguno.
  Future<Map<String, dynamic>?> currentShift() async {
    try {
      return _map(await _request('GET', '/shifts/current'));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> openShift(double openingAmount) async =>
      _map(await _request('POST', '/shifts/open',
          body: {'opening_amount': openingAmount}));

  /// Cierre a ciegas: se manda lo contado y la respuesta trae
  /// {shift, summary} con lo esperado y la diferencia.
  Future<Map<String, dynamic>> closeShift(double countedAmount,
          {String? notes}) async =>
      _map(await _request('POST', '/shifts/close', body: {
        'counted_amount': countedAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }));

  // ---------------------------------------------------------------------------
  // Ventas
  // ---------------------------------------------------------------------------

  /// [paymentMethod]: 'efectivo' | 'tarjeta' | 'transferencia'.
  /// [items]: [{'product_id': 1, 'quantity': 2}, ...]
  /// El precio lo calcula el servidor; la app no lo manda.
  Future<Map<String, dynamic>> createSale({
    required String paymentMethod,
    required List<Map<String, int>> items,
  }) async =>
      _map(await _request('POST', '/sales',
          body: {'payment_method': paymentMethod, 'items': items}));

  /// Historial paginado: {data: [...], current_page, last_page, ...}.
  Future<Map<String, dynamic>> sales({int page = 1}) async =>
      _map(await _request('GET', '/sales?page=$page'));

  Future<Map<String, dynamic>> cancelSale(int saleId) async =>
      _map(await _request('POST', '/sales/$saleId/cancel'));

  // ---------------------------------------------------------------------------
  // Gastos
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> expenses({int page = 1}) async =>
      _map(await _request('GET', '/expenses?page=$page'));

  Future<Map<String, dynamic>> createExpense(
          String description, double amount) async =>
      _map(await _request('POST', '/expenses',
          body: {'description': description, 'amount': amount}));
}
