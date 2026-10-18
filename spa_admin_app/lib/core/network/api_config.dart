enum Environment { local, production }

class ApiConfig {
  // Cambiar aquí a Environment.production cuando pases a la BD remota en Supabase
  static const Environment currentEnvironment = Environment.local;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.local:
      // '10.0.2.2' es el alias que usa el emulador de Android para referirse al 'localhost' de la PC
      // Si usas un dispositivo físico por USB, reemplaza '10.0.2.2' por la IP local de tu PC (ej. 192.168.1.50)
        return 'http://1192.168.56.1:3000/api/v1';
      case Environment.production:
        return 'https://tu-api-remota-spa.com/api/v1';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 15);
}