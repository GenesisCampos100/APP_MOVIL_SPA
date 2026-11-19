import '../services/api_service.dart';

class RecuperacionRepository {
  RecuperacionRepository._();
  static final RecuperacionRepository instance = RecuperacionRepository._();

  /// Pide que se envíe el código al correo (también sirve para reenviar).
  Future<void> solicitar(String correo) async {
    await ApiService.post(
      '/api/auth/recuperar/solicitar',
      {'correo': correo.trim().toLowerCase()},
    );
  }

  /// Valida el código y devuelve un token temporal.
  /// Lanza una excepción si el código es incorrecto.
  Future<String> verificar(String correo, String codigo) async {
    final data = await ApiService.post(
      '/api/auth/recuperar/verificar',
      {
        'correo': correo.trim().toLowerCase(),
        'codigo': codigo.trim(),
      },
    );

    final token = data is Map<String, dynamic>
        ? data['token'] as String?
        : null;

    if (token == null || token.isEmpty) {
      throw Exception('El servidor no devolvió el token de recuperación');
    }
    return token;
  }

  /// Guarda la nueva contraseña usando el token.
  Future<void> restablecer({
    required String correo,
    required String token,
    required String nuevaContrasena,
  }) async {
    await ApiService.post(
      '/api/auth/recuperar/restablecer',
      {
        'correo': correo.trim().toLowerCase(),
        'token': token,
        'nuevaContrasena': nuevaContrasena,
      },
    );
  }
}
