import '../models/usuario_sesion.dart';
import '../services/api_service.dart';
import '../services/sesion_service.dart';

class AuthRepository {
  // Se mantiene temporalmente porque la pantalla de
  // verificación todavía utiliza este valor.
  static const String codigoPrueba = '123456';

  /// POST /api/auth/verificar-correo
  Future<bool> existeCorreo(String correo) async {
    try {
      final data = await ApiService.post(
        '/api/auth/verificar-correo', //cambiar a /auth/verificar-correo
        {
          'correo': correo.trim().toLowerCase(),
        },
      );

      return data['existe'] == true;
    } catch (e) {
      throw Exception('Error al verificar el correo');
    }
  }

  /// POST /api/auth/login
  Future<UsuarioSesion?> iniciarSesion(
    String correo,
    String password,
  ) async {
    try {
      final data = await ApiService.post(
        '/api/auth/login', //cambiar a /auth/login
        {
          'correo': correo.trim().toLowerCase(),
          'contrasenia': password,
        },
      );

      final usuario = UsuarioSesion.fromJson(
        data['usuario'],
      );

      // Guardamos el usuario para utilizar su id_cliente
      // al registrar y consultar citas.
      SesionService.instance.iniciarSesion(usuario);

      return usuario;
    } catch (e) {
      final mensaje = e.toString();

      if (mensaje.contains('401')) {
        return null;
      }

      if (mensaje.contains('403')) {
        throw Exception('El usuario no tiene un rol permitido');
      }

      rethrow;
    }
  }

  /// POST /api/auth/registro
  Future<UsuarioSesion?> registrar({
    required String correo,
    required String nombre,
    required String apellido,
    String? apellidoMaterno,
    required String password,
  }) async {
    try {
      final data = await ApiService.post(
        '/api/auth/registro',
        {
          'correo': correo.trim().toLowerCase(),
          'contrasenia': password,
          'nombre': nombre,
          'apellido_p': apellido,
          'apellido_m': apellidoMaterno,
        },
      );

      final usuario = UsuarioSesion.fromJson(
        data['usuario'],
      );

      return usuario;
    } catch (e) {
      final mensaje = e.toString();

      if (mensaje.contains('409')) {
        throw Exception('El correo ya está registrado');
      }

      rethrow;
    }
  }

  // ---------------------------------------------------------
  // MÉTODOS TEMPORALES
  // ---------------------------------------------------------

  /// Se mantiene para que auth_verify_screen.dart siga compilando.
  ///
  /// Todavía utiliza el código de prueba 123456.
  Future<UsuarioSesion?> verificarCodigo(
    String correo,
    String codigo,
  ) async {
    if (codigo != codigoPrueba) {
      return null;
    }

    return UsuarioSesion(
      correo: correo.trim().toLowerCase(),
      nombre: '',
      apellido: '',
    );
  }

  /// Se mantiene para que telefono_screen.dart siga compilando.
  ///
  /// Todavía no tenemos una API para actualizar el teléfono.
  Future<void> guardarTelefono(
    String correo,
    String telefono,
  ) async {
    // Temporalmente no hace nada.
  }
}