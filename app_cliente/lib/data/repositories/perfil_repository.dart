import '../models/usuario_sesion.dart';

/// DATOS DE PRUEBA (mock). Con la API sería:
///   guardar -> PUT /clientes/perfil
///              (nombre, apellido_p, apellido_m, telefono, fecha_nacimiento)
/// El correo no se puede cambiar desde aquí.
class PerfilRepository {
  Future<UsuarioSesion> guardar(
    UsuarioSesion actual, {
    required String nombre,
    required String apellido,
    String? apellidoMaterno,
    String? telefono,
    DateTime? fechaNacimiento,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return actual.conPerfil(
      nombre: nombre,
      apellido: apellido,
      apellidoMaterno: apellidoMaterno,
      telefono: telefono,
      fechaNacimiento: fechaNacimiento,
    );
  }
}
