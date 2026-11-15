import 'package:flutter/foundation.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';

/// Sesión temporal del personal: se conserva únicamente en memoria.
/// El backend es quien debe verificar el JWT y el rol de cada solicitud.
/// No guardar tokens ni contraseñas en logs o en SharedPreferences.
class AuthSession {
  AuthSession._();

  /// Aplica preferencias únicamente con sesión activa (Administrador o Empleado).
  /// Al cerrar sesión el login siempre vuelve a claro y español.
  static final ValueNotifier<bool> temaPersonalActivo = ValueNotifier<bool>(false);

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
  // Compatibilidad con puestos personalizados: recepción conserva ID 5.
  // Los demás puestos de empleado acceden al panel de especialista;
  // los permisos reales siguen validándose en el backend.
  static bool get esEspecialista => esEmpleado &&
      idPuesto != null && idPuesto! > 0 && idPuesto != 5;

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
    temaPersonalActivo.value = esEmpleado || esAdministrador;
  }

  static void cerrar() {
    StaffPreferences.unbindUser();
    token = null;
    idUsuario = null;
    idEmpleado = null;
    idPuesto = null;
    correo = null;
    rol = null;
    temaPersonalActivo.value = false;
  }
}
