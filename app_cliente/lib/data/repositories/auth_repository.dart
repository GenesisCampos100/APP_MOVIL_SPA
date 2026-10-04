import '../models/usuario_sesion.dart';

class _Cuenta {
  final String nombre, apellido, password;
  final String? apellidoMaterno;
  const _Cuenta(this.nombre, this.apellido, this.password, [this.apellidoMaterno]);
}

/// DATOS DE PRUEBA (mock). Cuando Vanessa tenga la API, solo se cambia el
/// contenido de estos 4 métodos por llamadas HTTP; las pantallas no cambian.
///
///   existeCorreo      -> POST /auth/verificar-correo
///   iniciarSesion     -> POST /auth/login
///   registrar         -> POST /auth/registro
///                        (nombre, apellido_p, apellido_m, correo, password)
///   verificarCodigo   -> POST /auth/verificar-codigo
///
/// Cuenta de prueba ya registrada:  cliente@aura.com  /  Aura1234
/// Código de verificación de prueba: 123456
class AuthRepository {
  static const codigoPrueba = '123456';

  static final Map<String, _Cuenta> _cuentas = {
    'cliente@aura.com': const _Cuenta('Cliente', 'Demo', 'Aura1234', 'Aura'),
  };
  static final Map<String, _Cuenta> _pendientes = {};

  String _norm(String correo) => correo.trim().toLowerCase();

  Future<void> _espera() => Future.delayed(const Duration(milliseconds: 500));

  Future<bool> existeCorreo(String correo) async {
    await _espera();
    return _cuentas.containsKey(_norm(correo));
  }

  /// Devuelve el usuario si la contraseña es correcta, o null si no.
  Future<UsuarioSesion?> iniciarSesion(String correo, String password) async {
    await _espera();
    final c = _cuentas[_norm(correo)];
    if (c == null || c.password != password) return null;
    return UsuarioSesion(
      correo: _norm(correo),
      nombre: c.nombre,
      apellido: c.apellido,
      apellidoMaterno: c.apellidoMaterno,
    );
  }

  /// Guarda el registro como pendiente hasta confirmar el código.
  Future<void> registrar({
    required String correo,
    required String nombre,
    required String apellido,
    String? apellidoMaterno,
    required String password,
  }) async {
    await _espera();
    _pendientes[_norm(correo)] = _Cuenta(nombre, apellido, password, apellidoMaterno);
  }

  /// Devuelve el usuario si el código es correcto, o null si no.
  Future<UsuarioSesion?> verificarCodigo(String correo, String codigo) async {
    await _espera();
    final key = _norm(correo);
    final pendiente = _pendientes[key];
    if (pendiente == null || codigo != codigoPrueba) return null;
    _cuentas[key] = pendiente;
    _pendientes.remove(key);
    return UsuarioSesion(
      correo: key,
      nombre: pendiente.nombre,
      apellido: pendiente.apellido,
      apellidoMaterno: pendiente.apellidoMaterno,
    );
  }
}
