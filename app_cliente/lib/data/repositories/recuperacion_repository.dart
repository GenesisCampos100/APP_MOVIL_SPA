/// Recuperar contraseña (PRUEBA, sin backend).
///
/// Cualquier correo "recibe" el código [codigoPrueba]. Cuando el backend
/// tenga los endpoints, solo cambia el cuerpo de estos tres métodos; las
/// pantallas no se tocan:
///   POST /api/auth/recuperar/solicitar   {correo}
///   POST /api/auth/recuperar/verificar   {correo, codigo}  -> {token}
///   POST /api/auth/recuperar/restablecer {correo, token, nuevaContrasena}
class RecuperacionRepository {
  RecuperacionRepository._();
  static final RecuperacionRepository instance = RecuperacionRepository._();

  static const String codigoPrueba = '123456';
  static const String _tokenPrueba = 'token-de-prueba';

  Future<void> _espera() => Future.delayed(const Duration(milliseconds: 600));

  /// Pide que se envíe el código al correo (también sirve para reenviar).
  Future<void> solicitar(String correo) async {
    await _espera();
  }

  /// Valida el código y devuelve un token temporal.
  /// Lanza una excepción si el código es incorrecto.
  Future<String> verificar(String correo, String codigo) async {
    await _espera();
    if (codigo != codigoPrueba) {
      throw Exception('codigo_invalido');
    }
    return _tokenPrueba;
  }

  /// Guarda la nueva contraseña usando el token.
  Future<void> restablecer({
    required String correo,
    required String token,
    required String nuevaContrasena,
  }) async {
    await _espera();
    if (token != _tokenPrueba) {
      throw Exception('token_invalido');
    }
  }
}
