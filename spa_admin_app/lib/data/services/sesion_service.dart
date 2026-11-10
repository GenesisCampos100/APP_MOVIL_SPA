/// Sesión temporal del personal: se conserva únicamente en memoria.
/// El backend es quien debe verificar el JWT y el rol de cada solicitud.
/// No guardar tokens ni contraseñas en logs o en SharedPreferences.
class AuthSession {
  AuthSession._();

  static String? token;
  static int? idUsuario;
  static int? idEmpleado;
  static int? idPuesto;
  static String? correo;
  static String? rol;

  static bool get activa => token != null && token!.isNotEmpty;
  static bool get esAdministrador => rol?.trim().toLowerCase() == 'administrador';
  static bool get esEmpleado => rol?.trim().toLowerCase() == 'empleado';

  // La clasificación visual no sustituye la autorización del backend.
  static bool get esRecepcionista => esEmpleado && idPuesto == 5;
  static bool get esEspecialista => esEmpleado &&
      idPuesto != null && idPuesto! >= 1 && idPuesto! <= 4;

  static int? _entero(dynamic valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }

  static void iniciar({
    required String tokenRespuesta,
    required Map<String, dynamic> usuario,
  }) {
    token = tokenRespuesta;
    idUsuario = _entero(usuario['id_usuario']);
    idEmpleado = _entero(usuario['id_empleado']);
    idPuesto = _entero(usuario['id_puesto']);
    correo = usuario['correo']?.toString();
    rol = usuario['rol']?.toString();
  }

  static void cerrar() {
    token = null;
    idUsuario = null;
    idEmpleado = null;
    idPuesto = null;
    correo = null;
    rol = null;
  }
}
