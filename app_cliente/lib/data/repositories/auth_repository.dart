import '../models/usuario_sesion.dart';
import '../services/api_service.dart';
import '../../features/auth/auth_state.dart';

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
      '/api/auth/login',
      {
        'correo': correo.trim().toLowerCase(),
        'contrasenia': password,
      },
    );

    // Recuperar el token enviado por el backend.
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('El servidor no devolvió un token de acceso');
    }

    // Convertir los datos recibidos al modelo de usuario.
    final usuario = UsuarioSesion.fromJson(
      data['usuario'],
    );

    // Guardar usuario y JWT, y actualizar el estado de la aplicación.
    await AuthState.instance.iniciarSesion(
      usuario,
      token: token,
    );

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
 Future<bool> registrar({
  required String correo,
  required String nombre,
  required String apellido,
  String? apellidoMaterno,
  required String password,
}) async {
  final data = await ApiService.post(
    '/api/auth/registro',
    {
      'correo': correo.trim().toLowerCase(),
      'nombre': nombre,
      'apellido_p': apellido,
      'apellido_m': apellidoMaterno,
      'contrasenia': password,
    },
  );

  return data['requiereVerificacion'] == true;
}



  Future<UsuarioSesion?> verificarCodigo(
  String correo,
  String codigo,
) async {
  try {
    final data = await ApiService.post(
      '/api/auth/verificar-codigo',
      {
        'correo': correo.trim().toLowerCase(),
        'codigo': codigo.trim(),
      },
    );

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('El servidor no devolvió el token');
    }

    final usuario = UsuarioSesion.fromJson(
      data['usuario'] as Map<String, dynamic>,
    );

    await AuthState.instance.iniciarSesion(
      usuario,
      token: token,
    );

    return usuario;
  } catch (e) {
    final mensaje = e.toString();

    if (mensaje.contains('400')) return null;

    rethrow;
  }
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

  /// TEMPORAL: todavía no existe un endpoint para cambiar la contraseña.
  /// Por ahora solo comprueba que la contraseña actual sea correcta (con el
  /// login real) y NO cambia la contraseña en la base de datos.
  /// PUT /api/auth/cambiar-contrasena
  /// (contrasena_actual, contrasena_nueva).
  Future<bool> cambiarContrasena(
    String correo,
    String actual,
    String nueva,
  ) async {
    final usuario = await iniciarSesion(correo, actual);
    return usuario != null;
  }
}
