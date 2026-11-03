import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer $token', // Descomentar cuando agregues autenticación JWT
  };

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'Sin conexión a internet o servidor inaccesible');
    }
  }

  Future<dynamic> post(String path, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await _httpClient
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'Sin conexión a internet o servidor inaccesible');
    }
  }

  Future<dynamic> put(String path, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await _httpClient
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'Sin conexión a internet o servidor inaccesible');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await _httpClient
          .delete(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'Sin conexión a internet o servidor inaccesible');
    }
  }

  dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 400:
        throw ApiException(message: body['message'] ?? 'Petición incorrecta', statusCode: 400);
      case 401:
        throw ApiException(message: 'No autorizado', statusCode: 401);
      case 404:
        throw ApiException(message: 'Recurso no encontrado', statusCode: 404);
      case 500:
      default:
        throw ApiException(
          message: 'Error en el servidor (${response.statusCode})',
          statusCode: response.statusCode,
        );
    }
  }
}