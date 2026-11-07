/// Ajustes de red de la aplicación del personal.
/// Para el emulador Android, 10.0.2.2 apunta al equipo que ejecuta Node.js.
/// Para dispositivo físico o despliegue, pasar la URL con:
/// flutter run --dart-define=SPA_API_URL=https://servidor-ejemplo/api
/// La URL termina en /api (no /api/v1 en el backend de Vanessa).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SPA_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const Duration connectionTimeout = Duration(seconds: 15);
}
