import 'package:flutter/widgets.dart';
import 'idioma_state.dart';

/// Uso:  Text(context.t('perfil.favoritos'))
///       Text(context.t('comun.proximamente', {'que': 'Reagendar'}))
///
/// Para agregar un texto: crea la clave en 'es' y en 'en'. Si falta en
/// inglés se muestra en español, y si falta en los dos se muestra la clave.
extension TextosContext on BuildContext {
  String t(String clave, [Map<String, String>? datos]) {
    final codigo = IdiomaScope.codigoDe(this);
    var texto = _textos[codigo]?[clave] ?? _textos['es']?[clave] ?? clave;
    if (datos != null) {
      datos.forEach((k, v) => texto = texto.replaceAll('{$k}', v));
    }
    return texto;
  }

  /// Para textos que vienen de la base de datos (categorías, estados...).
  /// Si existe traducción en el idioma actual la usa; si no, deja el valor
  /// original tal como viene de la BD (por ejemplo, el nombre de un servicio).
  String tOr(String clave, String alternativa) {
    final codigo = IdiomaScope.codigoDe(this);
    return _textos[codigo]?[clave] ?? alternativa;
  }
}

const Map<String, Map<String, String>> _textos = {
  'es': {
    // Menú inferior
    'nav.inicio': 'Inicio',
    'nav.servicios': 'Servicios',
    'nav.citas': 'Citas',
    'nav.perfil': 'Perfil',

    // Comunes
    'comun.cancelar': 'Cancelar',
    'comun.proximamente': '{que}: próximamente',

    // Perfil
    'perfil.mi_perfil': 'Mi perfil',
    'perfil.favoritos': 'Favoritos',
    'perfil.mis_citas': 'Mis citas',
    'perfil.notificaciones': 'Notificaciones',
    'perfil.configuracion': 'Configuración',
    'perfil.tema': 'Tema',
    'perfil.cerrar_sesion': 'Cerrar sesión',
    'perfil.cerrar_pregunta': '¿Cerrar sesión?',

    // Configuración
    'config.titulo': 'Configuración',
    'config.notificaciones': 'Notificaciones',
    'config.recordatorios': 'Recordatorios de citas',
    'config.recordatorios_sub': 'Avisos para confirmar y recordar tus citas',
    'config.cuenta': 'Cuenta',
    'config.correo': 'Correo',
    'config.cambiar_contrasena': 'Cambiar contraseña',
    'config.legal': 'Legal',
    'config.privacidad': 'Política de privacidad',
    'config.terminos': 'Términos y condiciones',
    'config.eliminar_cuenta': 'Eliminar cuenta',
    'config.eliminar_pregunta': '¿Eliminar tu cuenta?',
    'config.eliminar_aviso': 'Esta acción no se puede deshacer.',
    'config.eliminar': 'Eliminar',
    'config.cuenta_eliminada': 'Tu cuenta fue eliminada',
    'config.version': 'Aura Spa · versión 1.0.0',
    'config.texto_pendiente':
        'Aquí se mostrará el texto completo de "{titulo}" de Aura Spa. Pendiente de redactar por el equipo.',

    // Idioma y tema
    'idioma.titulo': 'Idioma',
    'tema.titulo': 'Tema',
    'tema.claro': 'Claro',
    'tema.oscuro': 'Oscuro',
    'tema.automatico': 'Automático',
    'tema.automatico_sub': 'Según la configuración de tu celular',
  
    // Comunes (fase 2)
    'comun.deshacer': 'Deshacer',
    'comun.mxn': '{precio} MXN',

    // Inicio
    'home.buscar': 'Buscar.....',
    'home.promociones': 'Promociones',
    'home.categorias': 'Categorías',
    'home.destacados': 'Servicios Destacados',
    'home.desde': 'Desde {precio}',
    'home.reservar': 'Reservar',
    'home.error': 'No se pudieron cargar los servicios',
    'home.aura_spa': 'Aura Spa',

    // Catálogo
    'catalogo.titulo': 'Servicios',
    'catalogo.buscar': 'Buscar servicio',
    'catalogo.vacio': 'No hay servicios para mostrar',
    'catalogo.error': 'No se pudieron cargar los servicios',

    // Detalle del servicio
    'detalle.acerca': 'Acerca del servicio',
    'detalle.sin_descripcion': 'Este servicio aún no tiene descripción.',
    'detalle.agregar': 'Agregar',

    // Reseñas
    'resenas.titulo': 'Reseñas',
    'resenas.todas': 'Todas',
    'resenas.servicio': 'Servicio',
    'resenas.profesional': 'Profesional',
    'resenas.vacio_titulo': 'No hay reseñas encontradas',
    'resenas.vacio_msg': 'Este servicio aún no tiene reseñas.',

    // Favoritos
    'fav.titulo': 'Favoritos',
    'fav.servicios': 'Servicios',
    'fav.especialistas': 'Especialistas',
    'fav.vacio_serv_t': 'Sin servicios favoritos',
    'fav.vacio_serv_m': 'Toca el corazón en el detalle de un servicio para guardarlo aquí.',
    'fav.vacio_esp_t': 'Sin especialistas favoritos',
    'fav.vacio_esp_m': 'Toca el corazón al elegir a tu especialista para guardarlo aquí.',
    'fav.agregado': 'Agregado a favoritos',
    'fav.quitado': 'Quitado de favoritos',
    'fav.tip_agregar': 'Agregar a favoritos',
    'fav.tip_quitar': 'Quitar de favoritos',

    // Notificaciones
    'noti.titulo': 'Notificaciones',
    'noti.limpiar_todo': 'Limpiar todo',
    'noti.limpiar_pregunta': '¿Limpiar todas las notificaciones?',
    'noti.limpiar_conservan': 'Las que requieren tu confirmación se conservarán.',
    'noti.limpiar': 'Limpiar',
    'noti.sin_leer': '{n} sin leer',
    'noti.marcar_leidas': 'Marcar todas como leídas',
    'noti.eliminada': 'Notificación eliminada',
    'noti.confirmar_cita': 'Confirmar cita',
    'noti.cita_confirmada': 'Cita confirmada',
    'noti.vacio_t': 'Sin notificaciones',
    'noti.vacio_m': 'Aquí aparecerán los avisos de tus citas.',
    'noti.t.cita_creada': 'Cita registrada',
    'noti.m.cita_creada': 'Tu cita de {servicio} quedó registrada. Recuerda confirmarla 24 horas antes.',
    'noti.t.confirmar_cita': 'Confirma tu cita',
    'noti.m.confirmar_cita': 'Tu cita de {servicio} es mañana a las {hora}. Confírmala o se cancelará automáticamente.',
    'noti.t.cita_confirmada': 'Cita confirmada',
    'noti.m.cita_confirmada': 'Tu cita de {servicio} quedó confirmada. ¡Te esperamos en Aura Spa!',
    'noti.m.cita_confirmada_manual': 'Confirmaste tu cita. ¡Te esperamos en Aura Spa!',
    'noti.t.cita_cancelada': 'Cita cancelada',
    'noti.m.cita_cancelada': 'Tu cita de {servicio} se canceló porque no la confirmaste a tiempo. El horario quedó libre.',
    'noti.t.resena': '¿Cómo estuvo tu servicio?',
    'noti.m.resena': 'Cuéntanos tu experiencia con tu {servicio} escribiendo una reseña.',

    // Tiempo relativo
    'tiempo.ahora': 'ahora',
    'tiempo.hoy': 'hoy',
    'tiempo.ayer': 'ayer',
    'tiempo.min': 'hace {n} min',
    'tiempo.h': 'hace {n} h',
    'tiempo.dias': 'hace {n} días',
    'tiempo.mes': 'hace 1 mes',
    'tiempo.meses': 'hace {n} meses',
  },
  'en': {
    // Bottom bar
    'nav.inicio': 'Home',
    'nav.servicios': 'Services',
    'nav.citas': 'Appointments',
    'nav.perfil': 'Profile',

    // Common
    'comun.cancelar': 'Cancel',
    'comun.proximamente': '{que}: coming soon',

    // Profile
    'perfil.mi_perfil': 'My profile',
    'perfil.favoritos': 'Favorites',
    'perfil.mis_citas': 'My appointments',
    'perfil.notificaciones': 'Notifications',
    'perfil.configuracion': 'Settings',
    'perfil.tema': 'Theme',
    'perfil.cerrar_sesion': 'Log out',
    'perfil.cerrar_pregunta': 'Log out?',

    // Settings
    'config.titulo': 'Settings',
    'config.notificaciones': 'Notifications',
    'config.recordatorios': 'Appointment reminders',
    'config.recordatorios_sub': 'Alerts to confirm and remind you of your appointments',
    'config.cuenta': 'Account',
    'config.correo': 'Email',
    'config.cambiar_contrasena': 'Change password',
    'config.legal': 'Legal',
    'config.privacidad': 'Privacy policy',
    'config.terminos': 'Terms and conditions',
    'config.eliminar_cuenta': 'Delete account',
    'config.eliminar_pregunta': 'Delete your account?',
    'config.eliminar_aviso': 'This action cannot be undone.',
    'config.eliminar': 'Delete',
    'config.cuenta_eliminada': 'Your account was deleted',
    'config.version': 'Aura Spa · version 1.0.0',
    'config.texto_pendiente':
        'The full text of "{titulo}" for Aura Spa will be shown here. Pending to be written by the team.',

    // Language and theme
    'idioma.titulo': 'Language',
    'tema.titulo': 'Theme',
    'tema.claro': 'Light',
    'tema.oscuro': 'Dark',
    'tema.automatico': 'Automatic',
    'tema.automatico_sub': "Follows your phone's settings",

    // Common (phase 2)
    'comun.deshacer': 'Undo',
    'comun.mxn': '{precio} MXN',

    // Home
    'home.buscar': 'Search.....',
    'home.promociones': 'Promotions',
    'home.categorias': 'Categories',
    'home.destacados': 'Featured services',
    'home.desde': 'From {precio}',
    'home.reservar': 'Book',
    'home.error': 'Services could not be loaded',
    'home.aura_spa': 'Aura Spa',

    // Catalog
    'catalogo.titulo': 'Services',
    'catalogo.buscar': 'Search service',
    'catalogo.vacio': 'No services to show',
    'catalogo.error': 'Services could not be loaded',

    // Service detail
    'detalle.acerca': 'About this service',
    'detalle.sin_descripcion': 'This service has no description yet.',
    'detalle.agregar': 'Add',

    // Reviews
    'resenas.titulo': 'Reviews',
    'resenas.todas': 'All',
    'resenas.servicio': 'Service',
    'resenas.profesional': 'Professional',
    'resenas.vacio_titulo': 'No reviews found',
    'resenas.vacio_msg': 'This service has no reviews yet.',

    // Favorites
    'fav.titulo': 'Favorites',
    'fav.servicios': 'Services',
    'fav.especialistas': 'Specialists',
    'fav.vacio_serv_t': 'No favorite services',
    'fav.vacio_serv_m': 'Tap the heart on a service page to save it here.',
    'fav.vacio_esp_t': 'No favorite specialists',
    'fav.vacio_esp_m': 'Tap the heart when choosing your specialist to save them here.',
    'fav.agregado': 'Added to favorites',
    'fav.quitado': 'Removed from favorites',
    'fav.tip_agregar': 'Add to favorites',
    'fav.tip_quitar': 'Remove from favorites',

    // Notifications
    'noti.titulo': 'Notifications',
    'noti.limpiar_todo': 'Clear all',
    'noti.limpiar_pregunta': 'Clear all notifications?',
    'noti.limpiar_conservan': 'Those that need your confirmation will be kept.',
    'noti.limpiar': 'Clear',
    'noti.sin_leer': '{n} unread',
    'noti.marcar_leidas': 'Mark all as read',
    'noti.eliminada': 'Notification deleted',
    'noti.confirmar_cita': 'Confirm appointment',
    'noti.cita_confirmada': 'Appointment confirmed',
    'noti.vacio_t': 'No notifications',
    'noti.vacio_m': 'Alerts about your appointments will appear here.',
    'noti.t.cita_creada': 'Appointment booked',
    'noti.m.cita_creada': 'Your {servicio} appointment has been booked. Remember to confirm it 24 hours before.',
    'noti.t.confirmar_cita': 'Confirm your appointment',
    'noti.m.confirmar_cita': 'Your {servicio} appointment is tomorrow at {hora}. Confirm it or it will be cancelled automatically.',
    'noti.t.cita_confirmada': 'Appointment confirmed',
    'noti.m.cita_confirmada': 'Your {servicio} appointment is confirmed. We look forward to seeing you at Aura Spa!',
    'noti.m.cita_confirmada_manual': 'You confirmed your appointment. We look forward to seeing you at Aura Spa!',
    'noti.t.cita_cancelada': 'Appointment cancelled',
    'noti.m.cita_cancelada': 'Your {servicio} appointment was cancelled because you did not confirm it in time. The time slot is now free.',
    'noti.t.resena': 'How was your service?',
    'noti.m.resena': 'Tell us about your experience with your {servicio} by writing a review.',

    // Categories (names come from the database in Spanish)
    'cat.Corporal': 'Body',
    'cat.Facial': 'Facial',
    'cat.Manicure': 'Manicure',
    'cat.Aromaterapia': 'Aromatherapy',
    'cat.Pedicure': 'Pedicure',

    // Relative time
    'tiempo.ahora': 'now',
    'tiempo.hoy': 'today',
    'tiempo.ayer': 'yesterday',
    'tiempo.min': '{n} min ago',
    'tiempo.h': '{n} h ago',
    'tiempo.dias': '{n} days ago',
    'tiempo.mes': '1 month ago',
    'tiempo.meses': '{n} months ago',
  },
};
