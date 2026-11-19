import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_endpoints.dart';
import 'sesion_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Respeta el contrato de auth.controller.js de Vanessa:
  /// POST /api/auth/login con {correo, contrasenia}.
  /// Éxito: {mensaje, token, usuario:{id_usuario, correo, rol, ...}}.
  /// Error: {error: '...'}.
  static Future<Map<String, dynamic>> login(
    String correo,
    String contrasenia,
  ) async {
    final http.Response respuesta;
    try {
      respuesta = await http.post(
        Uri.parse('$baseUrl${ApiEndpoints.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'contrasenia': contrasenia,
        }),
      ).timeout(ApiConfig.connectionTimeout);
    } on TimeoutException {
      throw Exception('El servidor no respondió. Revisa que esté encendido.');
    } on SocketException {
      throw Exception('No se pudo establecer conexión con el servidor.');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el backend de Aura SPA.');
    }

    final dynamic datos;
    try {
      datos = jsonDecode(respuesta.body);
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta no válida.');
    }
    if (datos is! Map<String, dynamic>) {
      throw Exception('La respuesta del servidor tiene un formato inesperado.');
    }
    if (respuesta.statusCode != 200) {
      throw Exception(datos['error']?.toString() ??
          'No se pudo iniciar sesión (${respuesta.statusCode}).');
    }
    return datos;
  }

  /// Métodos genéricos existentes, preparados para enviar el token en el futuro.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthSession.activa)
          'Authorization': 'Bearer ${AuthSession.token}',
      };

  static Future<List<dynamic>> get(String endpoint) async {
    try {
      final respuesta = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      if (respuesta.statusCode != 200) {
        throw Exception('Error al consultar el servidor (${respuesta.statusCode})');
      }
      final datos = jsonDecode(respuesta.body);
      if (datos is! List) {
        throw Exception('La respuesta no contiene una lista.');
      }
      return datos;
    } on TimeoutException {
      throw Exception('La consulta tardó demasiado.');
    } on SocketException {
      throw Exception('Servidor inaccesible.');
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final respuesta = await http
          .post(Uri.parse('$baseUrl$endpoint'),
              headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);
      final dynamic datos = jsonDecode(respuesta.body);
      if (datos is! Map<String, dynamic>) {
        throw Exception('Formato de respuesta inesperado.');
      }
      if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
        throw Exception(datos['error']?.toString() ??
            'No se pudo registrar información (${respuesta.statusCode}).');
      }
      return datos;
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado.');
    } on SocketException {
      throw Exception('Servidor inaccesible.');
    }
  }
}
