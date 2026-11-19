import 'package:flutter/widgets.dart';
import '../i18n/textos.dart';
import '../../data/services/api_service.dart';

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
  'No se pudo cancelar la cita': 'err.cancelar_cita',
  'No se pudo reagendar la cita': 'err.reagendar_cita',
  'No se pudo publicar la reseña': 'err.publicar_resena',
  'No se pudieron obtener las reseñas': 'err.cargar_resenas',
  'Debes iniciar sesión para cancelar una cita': 'err.sesion_cancelar',
  'Debes iniciar sesión para confirmar una cita': 'err.sesion_confirmar',
  'Debes iniciar sesión para reagendar una cita': 'err.sesion_reagendar',
  'Debes iniciar sesión para guardar favoritos': 'err.sesion_favoritos',
};

/// Texto de un error listo para mostrar en el idioma elegido.
/// Si el mensaje es uno de los conocidos se traduce; lo que venga después
/// (por ejemplo, el detalle que manda el servidor) se deja tal cual.
String textoError(BuildContext context, Object error) {
  final mensaje = error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceAll('Exception:', '')
      .trim();

  if (error is ApiException) {
    if (error.codigo == 'CITA_FUERA_DE_PLAZO') {
      return context.t('citas.err_limite_cambio');
    }
    return _mensajePorEstado(context, error.statusCode);
  }

  final lower = mensaje.toLowerCase();
  if (lower.contains('socket') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection') ||
      lower.contains('conexión')) {
    return context.t('err.conexion');
  }

  final codigoHttp = RegExp(r'(?:^|[^0-9])(401|403|404|400|422|429|500|502|503|504)(?:[^0-9]|$)');
  final coincidencia = codigoHttp.firstMatch(lower);
  if (coincidencia != null) {
    return _mensajePorEstado(context, int.parse(coincidencia.group(1)!));
  }

  if (lower.contains('token') ||
      lower.contains('jwt') ||
      lower.contains('bearer') ||
      lower.contains('error ') ||
      lower.contains('exception')) {
    return context.t('err.solicitud');
  }

  for (final e in _conocidos.entries) {
    if (mensaje.startsWith(e.key)) {
      return context.t(e.value);
    }
  }

  return context.t('err.solicitud');
}

String _mensajePorEstado(BuildContext context, int statusCode) {
  switch (statusCode) {
    case 401:
    case 403:
      return context.t('err.sin_sesion');
    case 400:
    case 422:
      return context.t('err.datos_invalidos');
    case 404:
      return context.t('err.no_encontrado');
    case 429:
      return context.t('err.demasiados_intentos');
    case 503:
      return context.t('err.temporalmente_no_disponible');
    case 502:
    case 504:
      return context.t('err.no_disponible');
    case 500:
      return context.t('err.servidor');
    default:
      return context.t('err.solicitud');
  }
}
