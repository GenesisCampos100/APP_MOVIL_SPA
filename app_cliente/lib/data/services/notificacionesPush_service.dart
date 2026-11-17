
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sesion_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

  String? _tokenActual;

  Future<void> _inicializarNotificacionesLocales() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
    );

    const canal = AndroidNotificationChannel(
      'aura_spa_notificaciones',
      'Notificaciones de AuraSpa',
      description: 'Avisos de citas y novedades de AuraSpa.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  Future<void> inicializar() async {
    await _inicializarNotificacionesLocales();
    final configuracion = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Permiso de notificaciones: ${configuracion.authorizationStatus}',
    );

    FirebaseMessaging.onBackgroundMessage(
      manejarMensajeSegundoPlano,
    );

    _tokenActual = await _messaging.getToken();

    if (_tokenActual != null) {
      debugPrint('Token FCM obtenido correctamente.');
      await registrarTokenEnBackend();
    }

    _messaging.onTokenRefresh.listen((nuevoToken) {
      _tokenActual = nuevoToken;

      debugPrint('Token FCM actualizado.');

      registrarTokenEnBackend();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) async {
      debugPrint(
        'Notificación recibida: ${mensaje.notification?.title}',
      );

      final notificacion = mensaje.notification;

      if (notificacion == null) return;

      await _localNotifications.show(
        id: mensaje.hashCode,
        title: notificacion.title ?? 'AuraSpa',
        body: notificacion.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'aura_spa_notificaciones',
            'Notificaciones de AuraSpa',
            channelDescription:
                'Avisos de citas y novedades de AuraSpa.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  Future<void> registrarTokenEnBackend() async {
    try {
      final tokenSesion = SesionService.instance.token;

      if (tokenSesion == null || tokenSesion.isEmpty) {
        debugPrint(
          'No se registra FCM: no hay una sesión autenticada.',
        );
        return;
      }

      _tokenActual ??= await _messaging.getToken();

      if (_tokenActual == null || _tokenActual!.isEmpty) {
        return;
      }

      await ApiService.post(
        '/api/dispositivos',
        {
          'token_fcm': _tokenActual,
          'plataforma': kIsWeb ? 'web' : 'android',
        },
        token: tokenSesion,
      );

      debugPrint('Dispositivo registrado para notificaciones push.');
    } catch (e) {
      // Un fallo de notificaciones no debe impedir iniciar sesión.
      debugPrint('No se pudo registrar el dispositivo FCM: $e');
    }
  }
}
