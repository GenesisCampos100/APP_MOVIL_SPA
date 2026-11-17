
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';


@pragma('vm:entry-point')
Future<void> manejarMensajeSegundoPlano(RemoteMessage mensaje) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Notificación recibida en segundo plano: ${mensaje.messageId}',
  );
}

class NotificacionesPushService {
  NotificacionesPushService._();

  static final NotificacionesPushService instance =
      NotificacionesPushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> inicializar() async {
    // Solicitar autorización para recibir notificaciones.
    final configuracion = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Permiso de notificaciones: ${configuracion.authorizationStatus}',
    );

    // Registrar el manejador de mensajes en segundo plano.
    FirebaseMessaging.onBackgroundMessage(
      manejarMensajeSegundoPlano,
    );

    // Obtener el token FCM del dispositivo.
    final token = await _messaging.getToken();

    if (token != null) {
      debugPrint('Token FCM: $token');
    }

    // Escuchar actualizaciones del token.
    _messaging.onTokenRefresh.listen((nuevoToken) {
      debugPrint('Nuevo token FCM: $nuevoToken');
    });

    // Escuchar notificaciones cuando la aplicación está abierta.
    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) {
      debugPrint('Notificación recibida: ${mensaje.notification?.title}');
      debugPrint('Contenido: ${mensaje.notification?.body}');
    });
  }
}
