import 'package:flutter/material.dart';
import '../../data/models/servicio.dart';
import '../../features/auth/screens/auth_email_screen.dart';
import '../../features/auth/screens/auth_password_screen.dart';
import '../../features/auth/screens/auth_register_screen.dart';
import '../../features/auth/screens/auth_success_screen.dart';
import '../../features/auth/screens/auth_verify_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/catalog/screens/catalog_screen.dart';
import '../../features/service_detail/screens/service_detail_screen.dart';
import '../../features/shell/screens/main_shell.dart';
import '../../features/splash/screens/splash_screen.dart';

/// Mapa central de navegación: aquí se ven todas las "conexiones" de la app.
/// Las rutas que empiezan con '/auth' forman el flujo de inicio de sesión;
/// AuthFlow.terminar() las cierra todas de una vez.
class AppRoutes {
  static const splash = '/';
  static const shell = '/home';
  static const catalogo = '/catalogo'; // argumento opcional: String categoria
  static const detalle = '/servicio'; // argumento: Servicio
  static const reservar = '/reservar'; // argumento: Servicio

  // Flujo de autenticación
  static const authCorreo = '/auth/correo';
  static const authPassword = '/auth/password'; // argumento: String correo
  static const authRegistro = '/auth/registro'; // argumento: String correo
  static const authVerificar = '/auth/verificar'; // argumento: String correo
  static const authExito = '/auth/exito';

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case shell:
        page = const MainShell();
        break;
      case catalogo:
        page = CatalogScreen(
          categoriaInicial: settings.arguments as String?,
          conAtras: true,
        );
        break;
      case detalle:
        page = ServiceDetailScreen(servicio: settings.arguments as Servicio);
        break;
      case reservar:
        page = BookingScreen(servicio: settings.arguments as Servicio?);
        break;
      case authCorreo:
        page = const AuthEmailScreen();
        break;
      case authPassword:
        page = AuthPasswordScreen(correo: settings.arguments as String);
        break;
      case authRegistro:
        page = AuthRegisterScreen(correo: settings.arguments as String);
        break;
      case authVerificar:
        page = AuthVerifyScreen(correo: settings.arguments as String);
        break;
      case authExito:
        page = const AuthSuccessScreen();
        break;
      case splash:
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
