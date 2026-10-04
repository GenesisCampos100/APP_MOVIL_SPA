import 'package:flutter/foundation.dart';
import '../../data/models/usuario_sesion.dart';

/// Estado de sesión de toda la app: ¿hay un usuario con sesión iniciada?
/// Las pantallas lo escuchan con ListenableBuilder y se actualizan solas.
class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  UsuarioSesion? _usuario;

  UsuarioSesion? get usuario => _usuario;
  bool get isLoggedIn => _usuario != null;

  void iniciarSesion(UsuarioSesion usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrarSesion() {
    _usuario = null;
    notifyListeners();
  }
}
