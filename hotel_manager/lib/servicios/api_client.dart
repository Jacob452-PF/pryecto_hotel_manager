import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// URL base de la API. Puede cambiarse por entorno al compilar:
/// flutter run --dart-define=API_BASE_URL=https://.../api
const String kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://hotel-manager-api-ttg7.onrender.com/api',
);

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
  final int? categoryId;
  final bool active;

  Product.fromJson(Map<String, dynamic> j)
    : id = int.parse(j['id'].toString()),
      name = j['name']?.toString() ?? '',
      price = toDouble(j['price']),
      stock = int.tryParse(j['stock'].toString()) ?? 0,
      minStock = int.tryParse((j['min_stock'] ?? 0).toString()) ?? 0,
      category = (j['category'] as Map?)?['name']?.toString(),
      categoryId = int.tryParse((j['category_id'] ?? '').toString()),
      active = j['active'] as bool? ?? true;
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
      } else if (method == 'PATCH') {
        res = await http
            .patch(uri, headers: headers, body: payload)
            .timeout(_timeout);
      } else if (method == 'DELETE') {
        res = await http
            .delete(uri, headers: headers, body: payload)
            .timeout(_timeout);
      } else {
        res = await http.get(uri, headers: headers).timeout(_timeout);
      }
    } on TimeoutException {
      throw ApiException(
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
      );
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

  /// Normaliza listas simples y respuestas paginadas Laravel sin asumir que
  /// todos los endpoints devuelven la colección en la raíz.
  List<dynamic> listFromResponse(dynamic response, {String? collectionKey}) {
    if (response is List) return List<dynamic>.from(response);
    if (response is! Map) {
      throw const FormatException('La respuesta no contiene una lista.');
    }

    // Soporta respuestas como {rooms: [...]}, {data: [...]},
    // {data: {rooms: [...]}}, y la paginación Laravel {rooms: {data: [...]}}.
    final candidatos = <dynamic>[
      if (collectionKey != null) response[collectionKey],
      response['data'],
    ];
    for (final candidato in candidatos) {
      if (candidato is List) return List<dynamic>.from(candidato);
      if (candidato is Map) {
        final anidado = [
          if (collectionKey != null) candidato[collectionKey],
          candidato['data'],
        ];
        for (final valor in anidado) {
          if (valor is List) return List<dynamic>.from(valor);
          if (valor is Map && valor['data'] is List) {
            return List<dynamic>.from(valor['data'] as List);
          }
        }
      }
    }
    throw FormatException(
      'La respuesta no contiene la lista esperada'
      '${collectionKey == null ? '' : ' "$collectionKey"'}.',
    );
  }

  // ---------------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------------

  /// Inicia sesión, guarda el token y devuelve los datos del usuario
  /// ({id, name, email, role}).
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String deviceName = 'flutter',
  }) async {
    final data = await _request(
      'POST',
      '/login',
      body: {'email': email, 'password': password, 'device_name': deviceName},
    );
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
  // Habitaciones y huéspedes
  // ---------------------------------------------------------------------------

  /// El endpoint puede devolver `{summary, rooms}` o una lista directamente.
  /// Se conserva la respuesta original para que el servicio normalice ambos
  /// formatos (incluida la paginación Laravel).
  Future<dynamic> rooms() => _request('GET', '/rooms');

  Future<Map<String, dynamic>> updateRoomStatus(
    String roomId,
    Map<String, dynamic> payload,
  ) async => _map(
    await _request(
      'PATCH',
      '/rooms/${Uri.encodeComponent(roomId)}/status',
      body: payload,
    ),
  );

  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> room) async =>
      _map(await _request('POST', '/rooms', body: room));

  Future<Map<String, dynamic>> updateRoom(
    String roomId,
    Map<String, dynamic> room,
  ) async => _map(
    await _request('PUT', '/rooms/${Uri.encodeComponent(roomId)}', body: room),
  );

  Future<dynamic> guests({
    int page = 1,
    int perPage = 100,
    String? query,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    return _request('GET', '/guests?${Uri(queryParameters: params).query}');
  }

  Future<dynamic> guest(String guestId) async =>
      _request('GET', '/guests/${Uri.encodeComponent(guestId)}');

  Future<dynamic> createGuest(Map<String, dynamic> guest) async =>
      _request('POST', '/guests', body: guest);

  Future<dynamic> updateGuest(
    String guestId,
    Map<String, dynamic> guest, {
    bool partial = false,
  }) async => _request(
    partial ? 'PATCH' : 'PUT',
    '/guests/${Uri.encodeComponent(guestId)}',
    body: guest,
  );

  Future<void> deleteGuest(String guestId) async {
    await _request('DELETE', '/guests/${Uri.encodeComponent(guestId)}');
  }

  // ---------------------------------------------------------------------------
  // Catálogo
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> categories() async =>
      _list(await _request('GET', '/categories'));

  Future<Map<String, dynamic>> createCategory(String name) async =>
      _map(await _request('POST', '/categories', body: {'name': name}));

  Future<Map<String, dynamic>> updateCategory(
    int id,
    String name, {
    bool partial = false,
  }) async => _map(await _request(
    partial ? 'PATCH' : 'PUT',
    '/categories/$id',
    body: {'name': name},
  ));

  Future<void> deleteCategory(int id) async =>
      _request('DELETE', '/categories/$id');

  Future<List<Product>> products({String? search}) async {
    final qs = (search != null && search.isNotEmpty)
        ? '?q=${Uri.encodeQueryComponent(search)}'
        : '';
    final list = _list(await _request('GET', '/products$qs'));
    return list.map((e) => Product.fromJson(_map(e))).toList();
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async =>
      _map(await _request('POST', '/products', body: product));

  Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> product, {
    bool partial = false,
  }) async => _map(await _request(
    partial ? 'PATCH' : 'PUT',
    '/products/$id',
    body: product,
  ));

  Future<void> deleteProduct(int id) async => _request('DELETE', '/products/$id');

  Future<Map<String, dynamic>> createPurchase(
    List<Map<String, dynamic>> items, {
    int? supplierId,
  }) async => _map(await _request('POST', '/purchases', body: {
    if (supplierId != null) 'supplier_id': supplierId,
    'items': items,
  }));

  Future<dynamic> purchases({int page = 1}) =>
      _request('GET', '/purchases?page=$page');

  Future<dynamic> inventoryMovements({int page = 1}) =>
      _request('GET', '/inventory/movements?page=$page');

  Future<Map<String, dynamic>> dashboardReport({int days = 7}) async =>
      _map(await _request('GET', '/reports/dashboard?days=$days'));

  Future<dynamic> users({int page = 1}) =>
      _request('GET', '/users?page=$page');

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async =>
      _map(await _request('POST', '/users', body: user));

  Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> user,
  ) async => _map(await _request('PUT', '/users/$id', body: user));

  Future<dynamic> shifts({int page = 1}) =>
      _request('GET', '/shifts?page=$page');

  Future<Map<String, dynamic>> shift(int id) async =>
      _map(await _request('GET', '/shifts/$id'));

  Future<dynamic> rates() => _request('GET', '/rates');

  Future<dynamic> reservations({int page = 1}) =>
      _request('GET', '/reservations?page=$page&per_page=100');

  Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> reservation,
  ) async => _map(await _request('POST', '/reservations', body: reservation));

  Future<Map<String, dynamic>> cancelReservation(String id) async => _map(
    await _request('POST', '/reservations/${Uri.encodeComponent(id)}/cancel'),
  );

  Future<Map<String, dynamic>> payReservation(
    String id, {
    required double amount,
    required String paymentMethod,
  }) async => _map(
    await _request(
      'POST',
      '/reservations/${Uri.encodeComponent(id)}/payments',
      body: {'amount': amount, 'payment_method': paymentMethod},
    ),
  );

  Future<Map<String, dynamic>> checkInReservation(
    String id, {
    required String paymentMethod,
    List<Map<String, int>> items = const [],
  }) async => _map(
    await _request(
      'POST',
      '/reservations/${Uri.encodeComponent(id)}/check-in',
      body: {
        'payment_method': paymentMethod,
        if (items.isNotEmpty) 'items': items,
      },
    ),
  );

  Future<Map<String, dynamic>> createStay(
    Map<String, dynamic> stay,
  ) async => _map(await _request('POST', '/stays', body: stay));

  Future<dynamic> stays({int page = 1}) =>
      _request('GET', '/stays?page=$page');

  Future<Map<String, dynamic>> chargeStay(
    String id, {
    double? amount,
    String? description,
    List<Map<String, int>> items = const [],
    required bool payNow,
    String? paymentMethod,
  }) async => _map(
    await _request(
      'POST',
      '/stays/${Uri.encodeComponent(id)}/charge',
      body: {
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
        if (items.isNotEmpty) 'items': items,
        'pay_now': payNow,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      },
    ),
  );

  Future<Map<String, dynamic>> checkoutStay(
    String id, {
    String? paymentMethod,
  }) async => _map(
    await _request(
      'POST',
      '/stays/${Uri.encodeComponent(id)}/checkout',
      body: {if (paymentMethod != null) 'payment_method': paymentMethod},
    ),
  );

  Future<dynamic> tasks({int page = 1}) =>
      _request('GET', '/tasks?page=$page&per_page=100');

  Future<Map<String, dynamic>> createTask(
    Map<String, dynamic> task,
  ) async => _map(await _request('POST', '/tasks', body: task));

  Future<Map<String, dynamic>> assignTask(
    String id,
    String userId,
  ) async {
    final assignedTo = int.tryParse(userId);
    if (assignedTo == null) {
      throw ArgumentError.value(userId, 'userId', 'Debe ser un ID numérico del servidor.');
    }
    return _map(
      await _request(
        'PATCH',
        '/tasks/${Uri.encodeComponent(id)}/assign',
        body: {'assigned_to': assignedTo},
      ),
    );
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    String id,
    String status, {
    String? result,
  }) async => _map(
    await _request(
      'PATCH',
      '/tasks/${Uri.encodeComponent(id)}/status',
      body: {'status': status, if (result != null) 'result': result},
    ),
  );

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

  Future<Map<String, dynamic>> openShift(double openingAmount) async => _map(
    await _request(
      'POST',
      '/shifts/open',
      body: {'opening_amount': openingAmount},
    ),
  );

  /// Cierre a ciegas: se manda lo contado y la respuesta trae
  /// {shift, summary} con lo esperado y la diferencia.
  Future<Map<String, dynamic>> closeShift(
    double countedAmount, {
    String? notes,
  }) async => _map(
    await _request(
      'POST',
      '/shifts/close',
      body: {
        'counted_amount': countedAmount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    ),
  );

  // ---------------------------------------------------------------------------
  // Ventas
  // ---------------------------------------------------------------------------

  /// [paymentMethod]: 'efectivo' | 'tarjeta' | 'transferencia'.
  /// [items]: [{'product_id': 1, 'quantity': 2}, ...]
  /// El precio lo calcula el servidor; la app no lo manda.
  Future<Map<String, dynamic>> createSale({
    required String paymentMethod,
    required List<Map<String, int>> items,
  }) async => _map(
    await _request(
      'POST',
      '/sales',
      body: {'payment_method': paymentMethod, 'items': items},
    ),
  );

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
    String description,
    double amount,
  ) async => _map(
    await _request(
      'POST',
      '/expenses',
      body: {'description': description, 'amount': amount},
    ),
  );
}
