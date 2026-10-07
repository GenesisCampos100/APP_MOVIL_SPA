import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

class ApiService {
  // URL base para el backend en Node.js y Express
  // Nota: Si usas emulador Android, usa 'http://10.0.2.2:3000/api'. Si usas dispositivo físico, usa la IP de tu PC.
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // --- AUTENTICACIÓN (Tabla USUARIOS) ---
  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiEndpoints.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // Retorna datos del usuario/token
      } else {
        throw Exception(data['message'] ?? 'Credenciales incorrectas o usuario inactivo');
      }
    } catch (e) {
      throw Exception('Error de conexión con el servidor: $e');
    }
  }

  // --- MÉTODOS GENÉRICOS DE CONSUMO API ---
  static Future<List<dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al consultar el servidor (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Error al registrar información');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }
}
