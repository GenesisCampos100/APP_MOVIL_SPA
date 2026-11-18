
import 'package:flutter/foundation.dart';

import '../../data/models/usuario_sesion.dart';
import '../../data/services/sesion_service.dart';

/// Estado de sesión de toda la aplicación.
class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  UsuarioSesion? _usuario;

  bool _cargandoSesion = false;
  bool _errorConexion = false;

  UsuarioSesion? get usuario => _usuario;
  bool get isLoggedIn => _usuario != null;
  bool get cargandoSesion => _cargandoSesion;
  bool get errorConexion => _errorConexion;

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
    _errorConexion = false;
    notifyListeners();
  }

  /// Recupera la sesión guardada y valida el JWT.
  Future<void> restaurarSesion() async {
    _cargandoSesion = true;
    _errorConexion = false;
    notifyListeners();

    try {
      final usuario =
          await SesionService.instance.restaurarSesion();

      _usuario = usuario;
    } catch (e) {
      // Error de conexión: conservar los datos almacenados.
      _errorConexion = true;
      _usuario = null;
    } finally {
      _cargandoSesion = false;
      notifyListeners();
    }
  }

  void actualizarTelefono(String telefono) {
    final actual = _usuario;
    if (actual == null) return;

    _usuario = actual.copyWith(telefono: telefono);
    notifyListeners();
  }

  /// Reemplaza los datos del usuario después de editar su perfil.
  Future<void> actualizarPerfil(UsuarioSesion nuevo) async {
    if (_usuario == null) return;

    final token = SesionService.instance.token;

    // Guardar el usuario actualizado sin perder el JWT.
    await SesionService.instance.iniciarSesion(
      nuevo,
      token: token,
    );

    _usuario = nuevo;
    notifyListeners();
  }

  /// Cierra la sesión y elimina los datos almacenados.
  Future<void> cerrarSesion() async {
    await SesionService.instance.cerrarSesion();

    _usuario = null;
    _errorConexion = false;
    notifyListeners();
  }
}
