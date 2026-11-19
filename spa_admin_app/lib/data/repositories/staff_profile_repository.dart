import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/sesion_service.dart';

class StaffProfileRepository {
  const StaffProfileRepository._();

  static final ValueNotifier<int> profileRevision = ValueNotifier<int>(0);

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AuthSession.token ?? ''}',
    'Content-Type': 'application/json',
  };

  static String? imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return (uri.scheme == 'https' || uri.scheme == 'http') ? path : null;
    }
    if (!path.startsWith('/uploads/')) return null;
    return '${Uri.parse(ApiConfig.baseUrl).origin}$path';
  }

  static Map<String, dynamic> _parse(http.Response response) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('El servidor devolvió información no válida.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta inesperado.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error']?.toString() ??
          'No se pudo completar la operación (${response.statusCode}).');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> obtener() async {
    if (!AuthSession.activa) throw Exception('La sesión ya no está activa.');
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/perfil'),
      headers: _headers,
    ).timeout(ApiConfig.connectionTimeout);
    final data = _parse(res)['usuario'];
    if (data is! Map<String, dynamic>) {
      throw Exception('No se recibió el perfil del personal.');
    }
    return data;
  }

  static Future<Map<String, dynamic>> editar(Map<String, dynamic> values) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/perfil'),
      headers: _headers,
      body: jsonEncode(values),
    ).timeout(ApiConfig.connectionTimeout);
    final data = _parse(res)['usuario'];
    if (data is! Map<String, dynamic>) {
      throw Exception('No se recibió el perfil actualizado.');
    }
    profileRevision.value++;
    return data;
  }

  /// Selección desde image_picker; el backend decide formato y nombre del archivo.
  static Future<Map<String, dynamic>> subirFoto(List<int> bytes, String mime) async {
    if (!AuthSession.activa) throw Exception('La sesión ya no está activa.');
    if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) {
      throw Exception('La fotografía debe pesar menos de 3 MB.');
    }
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/foto'),
      headers: {
        'Authorization': 'Bearer ${AuthSession.token}',
        'Content-Type': mime,
      },
      body: bytes,
    ).timeout(const Duration(seconds: 30));
    final data = _parse(res);
    profileRevision.value++;
    return data;
  }
}
