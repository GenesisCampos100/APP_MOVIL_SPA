import 'package:flutter/material.dart';
import '../../features/auth/screens/login_admin_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

/// Rutas de entrada. El acceso a los paneles continúa condicionado al login
/// y al rol validado; no hay rutas públicas directas a paneles protegidos.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget pantalla;
    switch (settings.name) {
      case splash:
        pantalla = const SplashScreen();
        break;
      case login:
      default:
        pantalla = const LoginAdminScreen();
    }
    return MaterialPageRoute<void>(
      builder: (_) => pantalla,
      settings: settings,
    );
  }
}
