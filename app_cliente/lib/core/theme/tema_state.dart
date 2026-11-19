import 'package:flutter/material.dart';

/// Tema elegido por el usuario: claro, oscuro o automático (el del celular).
/// Por ahora solo vive en memoria: al cerrar la app vuelve a "Claro".
/// Para que se conserve, se puede guardar con el paquete shared_preferences.
class TemaState extends ChangeNotifier {
  TemaState._();
  static final TemaState instance = TemaState._();

  ThemeMode _modo = ThemeMode.light;
  ThemeMode get modo => _modo;

  void cambiar(ThemeMode nuevo) {
    if (nuevo == _modo) return;
    _modo = nuevo;
    notifyListeners();
  }
}
