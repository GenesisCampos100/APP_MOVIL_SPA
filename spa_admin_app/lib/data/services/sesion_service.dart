/// Sesión temporal del personal: se conserva únicamente en memoria.
/// El backend es quien debe verificar el JWT y el rol de cada solicitud.
/// No guardar tokens ni contraseñas en logs o en SharedPreferences.
class AuthSession {
  AuthSession._();

  static String? token;
  static int? idUsuario;
  static String? correo;
  static String? rol;

  static bool get activa => token != null && token!.isNotEmpty;
  static bool get esAdministrador => rol?.trim().toLowerCase() == 'administrador';
  static bool get esEmpleado => rol?.trim().toLowerCase() == 'empleado';

  static void iniciar({
    required String tokenRespuesta,
    required Map<String, dynamic> usuario,
  }) {
    final id = usuario['id_usuario'];
    token = tokenRespuesta;
    idUsuario = id is num ? id.toInt() : int.tryParse('$id');
    correo = usuario['correo']?.toString();
    rol = usuario['rol']?.toString();
  }

  static void cerrar() {
    token = null;
    idUsuario = null;
    correo = null;
    rol = null;
  }
}
