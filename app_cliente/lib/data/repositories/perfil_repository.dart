
import '../models/usuario_sesion.dart';
import '../services/api_service.dart';
import '../services/sesion_service.dart';

class PerfilRepository {
  Future<UsuarioSesion> guardar({
    required String nombre,
    required String apellido,
    String? apellidoMaterno,
    String? telefono,
    DateTime? fechaNacimiento,
  }) async {
    final sesion = SesionService.instance;
    final token = sesion.token;

    if (!sesion.estaIniciada || token == null) {
      throw Exception('No hay una sesión activa');
    }

    final respuesta = await ApiService.put(
      '/api/usuarios/perfil',
      {
        'nombre': nombre.trim(),
        'apellido_p': apellido.trim(),
        'apellido_m': apellidoMaterno?.trim().isEmpty == true
            ? null
            : apellidoMaterno?.trim(),
        'telefono': telefono?.trim().isEmpty == true
            ? null
            : telefono?.trim(),
        'fecha_nacimiento': fechaNacimiento == null
            ? null
            : fechaNacimiento.toIso8601String().split('T').first,
      },
      token: token,
    );

    final usuarioJson = Map<String, dynamic>.from(
      respuesta['usuario'],
    );

    return UsuarioSesion.fromJson(usuarioJson);
  }

  // SOLICITAR CÓDIGO PARA EL NUEVO CORREO
  Future<void> solicitarCambioCorreo(String correo) async {
    final sesion = SesionService.instance;
    final token = sesion.token;

    if (!sesion.estaIniciada || token == null) {
      throw Exception('No hay una sesión activa');
    }

    await ApiService.post(
      '/api/usuarios/perfil/cambiar-correo',
      {'correo': correo.trim()},
      token: token,
    );
  }

  // VERIFICAR CÓDIGO Y ACTUALIZAR CORREO
  Future<UsuarioSesion> verificarCambioCorreo({
    required String correo,
    required String codigo,
  }) async {
    final sesion = SesionService.instance;
    final token = sesion.token;

    if (!sesion.estaIniciada || token == null) {
      throw Exception('No hay una sesión activa');
    }

    final respuesta = await ApiService.post(
      '/api/usuarios/perfil/verificar-cambio-correo',
      {
        'correo': correo.trim(),
        'codigo': codigo.trim(),
      },
      token: token,
    );

    final usuarioJson = Map<String, dynamic>.from(
      respuesta['usuario'],
    );

    return UsuarioSesion.fromJson(usuarioJson);
  }
}
