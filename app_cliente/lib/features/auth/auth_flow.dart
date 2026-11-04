import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import 'auth_state.dart';

/// Ayudas para entrar y salir del flujo de autenticación.
class AuthFlow {
  /// Abre el inicio de sesión desde cualquier parte (por ejemplo, al reservar).
  /// Cuando el flujo termina, regresa a la pantalla de origen y devuelve
  /// true si el usuario quedó con sesión iniciada.
  static Future<bool> iniciar(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.authCorreo);
    return AuthState.instance.isLoggedIn;
  }

  /// Cierra todas las pantallas de autenticación (rutas '/auth/...') y
  /// vuelve a la pantalla desde donde se abrió el flujo.
  static void terminar(BuildContext context) {
    Navigator.of(context).popUntil(
      (ruta) => !(ruta.settings.name ?? '').startsWith('/auth'),
    );
  }
}
