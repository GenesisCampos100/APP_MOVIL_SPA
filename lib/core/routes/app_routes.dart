import 'package:flutter/material.dart';
import '../../data/models/servicio.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/catalog/screens/catalog_screen.dart';
import '../../features/service_detail/screens/service_detail_screen.dart';
import '../../features/shell/screens/main_shell.dart';
import '../../features/splash/screens/splash_screen.dart';

/// Mapa central de navegación: aquí se ven todas las "conexiones" de la app.
class AppRoutes {
  static const splash = '/';
  static const shell = '/home';
  static const catalogo = '/catalogo'; // argumento opcional: String categoria
  static const detalle = '/servicio'; // argumento: Servicio
  static const reservar = '/reservar'; // argumento: Servicio
  static const login = '/login';

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
      case login:
        page = const LoginScreen();
        break;
      case splash:
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
