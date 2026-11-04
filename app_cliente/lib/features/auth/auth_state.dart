
import 'package:flutter/foundation.dart';

import '../../data/models/usuario_sesion.dart';
import '../../data/services/sesion_service.dart';

/// Estado de sesión de toda la aplicación.
class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  UsuarioSesion? _usuario;

  UsuarioSesion? get usuario => _usuario;
  bool get isLoggedIn => _usuario != null;

  /// Inicia sesión y guarda los datos de forma persistente.
  Future<void> iniciarSesion(
    UsuarioSesion usuario, {
    required String token,
  }) async {
    await SesionService.instance.iniciarSesion(
      usuario,
      token: token,
    );

    _usuario = usuario;
    notifyListeners();
  }

  /// Recupera la sesión guardada en el dispositivo.
  Future<void> restaurarSesion() async {
    final usuario = await SesionService.instance.restaurarSesion();

    _usuario = usuario;
    notifyListeners();
  }

  void actualizarTelefono(String telefono) {
    final actual = _usuario;
    if (actual == null) return;

    _usuario = actual.copyWith(telefono: telefono);
    notifyListeners();
  }

  /// Reemplaza los datos del usuario después de editar su perfil.
  void actualizarPerfil(UsuarioSesion nuevo) {
    if (_usuario == null) return;

    _usuario = nuevo;
    notifyListeners();
  }

  /// Cierra la sesión y elimina los datos almacenados.
  Future<void> cerrarSesion() async {
    await SesionService.instance.cerrarSesion();

    _usuario = null;
    notifyListeners();
  }
}
