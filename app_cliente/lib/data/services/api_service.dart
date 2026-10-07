import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  //static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://192.168.100.10:3000';

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
    );

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

    print('>>> API POST: $url');
    print('>>> BODY: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    return _procesarRespuesta(response);
  }

  static dynamic _procesarRespuesta(http.Response response) {
    print('>>> API STATUS: ${response.statusCode}');
    print('>>> API BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      throw Exception(
        '${response.statusCode}: '
        '${data['error'] ?? data['mensaje'] ?? 'Error en la solicitud'}',
      );
    }

    throw Exception('Error en la solicitud');
  }
}