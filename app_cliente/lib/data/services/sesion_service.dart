
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario_sesion.dart';

class SesionService {
  SesionService._();

  static final SesionService instance = SesionService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyUsuario = 'usuario_sesion';
  static const String _keyToken = 'token_sesion';

  UsuarioSesion? _usuario;
  String? _token;

  UsuarioSesion? get usuario => _usuario;
  String? get token => _token;

  bool get estaIniciada => _usuario != null && _token != null;

  int? get idCliente => _usuario?.idCliente;

  // Guardar usuario y token de forma segura.
  Future<void> iniciarSesion(
    UsuarioSesion usuario, {
    String? token,
  }) async {
    _usuario = usuario;
    _token = token;

    await _storage.write(
      key: _keyUsuario,
      value: jsonEncode(usuario.toJson()),
    );

    if (token != null) {
      await _storage.write(
        key: _keyToken,
        value: token,
      );
    }
  }

  // Recuperar la sesión almacenada.
  Future<UsuarioSesion?> restaurarSesion() async {
    try {
      final usuarioGuardado = await _storage.read(key: _keyUsuario);
      final tokenGuardado = await _storage.read(key: _keyToken);

      if (usuarioGuardado == null || tokenGuardado == null) {
        await cerrarSesion();
        return null;
      }

      final datos = jsonDecode(usuarioGuardado) as Map<String, dynamic>;

      _usuario = UsuarioSesion.fromJson(datos);
      _token = tokenGuardado;

      return _usuario;
    } catch (e) {
      await cerrarSesion();
      return null;
    }
  }

  // Eliminar la sesión almacenada.
  Future<void> cerrarSesion() async {
    _usuario = null;
    _token = null;

    await _storage.delete(key: _keyUsuario);
    await _storage.delete(key: _keyToken);
  }
}
