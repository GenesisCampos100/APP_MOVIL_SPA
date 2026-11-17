import 'package:flutter/widgets.dart';
import '../i18n/textos.dart';

/// Mensajes de error que genera la app, tal como llegan en español, y la
/// clave del diccionario con su traducción.
const Map<String, String> _conocidos = {
  'Debes iniciar sesión para consultar tus citas': 'err.sesion_citas',
  'Debes iniciar sesión para apartar un horario': 'err.sesion_apartar',
  'Debes iniciar sesión para cancelar el apartado': 'err.sesion_cancelar_apartado',
  'Debes iniciar sesión para confirmar la cita': 'err.sesion_confirmar',
  'Debes iniciar sesión para registrar una cita': 'err.sesion_registrar',
  'La sesión no tiene los datos necesarios': 'err.sesion_datos',
  'No se pudieron cargar tus citas': 'err.cargar_citas',
  'No se pudo apartar el horario': 'err.apartar',
  'No se pudo cancelar el apartado': 'err.cancelar_apartado',
  'No se pudo confirmar la cita': 'err.confirmar_cita',
  'La respuesta de disponibilidad no es válida.': 'err.disponibilidad',
  'Error al verificar el correo': 'err.verificar_correo',
  'El servidor no devolvió un token de acceso': 'err.sin_token',
  'El servidor no devolvió el token': 'err.sin_token',
  'El usuario no tiene un rol permitido': 'err.sin_rol',
  'No hay una sesión activa': 'err.sin_sesion',
  'El correo ya está registrado': 'err.correo_registrado',
  'Cancelar citas todavía no está disponible en el servidor.': 'err.cancelar_no_disponible',
  'Error en la solicitud': 'err.solicitud',
};

/// Texto de un error listo para mostrar en el idioma elegido.
/// Si el mensaje es uno de los conocidos se traduce; lo que venga después
/// (por ejemplo, el detalle que manda el servidor) se deja tal cual.
String textoError(BuildContext context, Object error) {
  final mensaje =
      error.toString().replaceFirst('Exception: ', '').trim();
  for (final e in _conocidos.entries) {
    if (mensaje.startsWith(e.key)) {
      final resto =
          mensaje.substring(e.key.length).replaceAll('Exception: ', '');
      return context.t(e.value) + resto;
    }
  }
  return mensaje;
}
