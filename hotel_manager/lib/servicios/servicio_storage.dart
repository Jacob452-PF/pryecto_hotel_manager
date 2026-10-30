import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Almacén temporal JSON; TODO(API): reemplazar por repositorio remoto + caché.
class ServicioStorage {
  ServicioStorage._();
  static final instancia = ServicioStorage._();

  Future<List<Map<String, dynamic>>> leerLista(String clave) async {
    final raw = (await SharedPreferences.getInstance()).getString(clave);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } on FormatException {
      return [];
    }
  }

  Future<void> guardarLista(
    String clave,
    List<Map<String, dynamic>> datos,
  ) async {
    await (await SharedPreferences.getInstance()).setString(
      clave,
      jsonEncode(datos),
    );
  }

  Future<Map<String, dynamic>?> leerObjeto(String clave) async {
    final raw = (await SharedPreferences.getInstance()).getString(clave);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> guardarObjeto(String clave, Map<String, dynamic> dato) async {
    await (await SharedPreferences.getInstance()).setString(
      clave,
      jsonEncode(dato),
    );
  }
}
