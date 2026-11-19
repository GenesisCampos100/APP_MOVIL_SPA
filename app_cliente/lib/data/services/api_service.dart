import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String? codigo;
  final String? mensajeServidor;

  const ApiException(
    this.statusCode, {
    this.codigo,
    this.mensajeServidor,
  });

  @override
  String toString() => 'Error $statusCode';
}

class ApiService {

  static const String baseUrl = String.fromEnvironment(
    'SPA_CLIENT_API_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static Future<dynamic> get(
    String endpoint, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '$baseUrl$endpoint';

    print('>>> API GET: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    )
    .timeout(const Duration(seconds: 8));

    return _procesarRespuesta(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '$baseUrl$endpoint';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 8));

    return _procesarRespuesta(response);
  }


  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '$baseUrl$endpoint';

    print('>>> API PUT: $url');
    print('>>> BODY: ${jsonEncode(body)}');

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 8));

    return _procesarRespuesta(response);
  }


  static Future<dynamic> putFile(
    String endpoint,
    String filePath, {
    String fieldName = 'foto',
    String? token,
  }) async {
    final url = '$baseUrl$endpoint';

    print('>>> API PUT FILE: $url');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(url),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        filePath,
      ),
    );

    final streamedResponse = await request.send()
        .timeout(const Duration(seconds: 30));

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    return _procesarRespuesta(response);
  }




  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '$baseUrl$endpoint';

    print('>>> API PATCH: $url');

    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 8));

    return _procesarRespuesta(response);
  }



  static Future<dynamic> delete(
    String endpoint, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = '$baseUrl$endpoint';

    print('>>> API DELETE: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 8));

    return _procesarRespuesta(response);
  }



  static dynamic _procesarRespuesta(http.Response response) {
    print('>>> API STATUS: ${response.statusCode}');
    print('>>> API BODY: ${response.body}');

    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String? mensajeServidor;
    String? codigo;
    if (data is Map<String, dynamic>) {
      final valor = data['error'] ?? data['mensaje'];
      if (valor is String && valor.trim().isNotEmpty) {
        mensajeServidor = valor.trim();
      }
      if (data['codigo'] is String) {
        codigo = data['codigo'] as String;
      }
    }

    throw ApiException(
      response.statusCode,
      codigo: codigo,
      mensajeServidor: mensajeServidor,
    );
  }
}