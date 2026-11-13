import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';
import 'sesion_service.dart';

/// Cliente HTTP compartido: incluye JWT y traduce errores HTTP.
class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthSession.activa)
          'Authorization': 'Bearer ${AuthSession.token}',
      };

  Future<dynamic> get(String path) => _request(
        () => _httpClient.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers),
      );

  Future<dynamic> post(String path, {required Map<String, dynamic> body}) => _request(
        () => _httpClient.post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );

  Future<dynamic> put(String path, {required Map<String, dynamic> body}) => _request(
        () => _httpClient.put(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );

  Future<dynamic> delete(String path) => _request(
        () => _httpClient.delete(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers),
      );

  Future<dynamic> _request(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(ApiConfig.connectionTimeout);
      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'El servidor tardó demasiado. Intenta nuevamente.');
    } on SocketException {
      throw ApiException(message: 'Sin conexión a internet o servidor inaccesible.');
    } on http.ClientException {
      throw ApiException(message: 'No se pudo establecer conexión con el servidor.');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    if (response.body.trim().isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          message: 'El servidor devolvió una respuesta no válida.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String? errorServidor;
    if (body is Map && body['error'] is String) {
      errorServidor = body['error'] as String;
    }

    final mensaje = switch (response.statusCode) {
      400 => errorServidor ?? 'Revisa los datos introducidos.',
      401 => 'Tu sesión no es válida o ha expirado. Inicia sesión nuevamente.',
      403 => 'No tienes permiso para realizar esta operación.',
      404 => errorServidor ?? 'No se encontró el recurso solicitado.',
      409 => errorServidor ?? 'La operación entra en conflicto con los datos actuales.',
      429 => 'Demasiadas solicitudes. Inténtalo más tarde.',
      _ => 'Error en el servidor (${response.statusCode}).',
    };
    throw ApiException(message: mensaje, statusCode: response.statusCode);
  }
}
