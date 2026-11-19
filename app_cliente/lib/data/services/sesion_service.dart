
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario_sesion.dart';

import 'api_service.dart';

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
    } else {
      await _storage.delete(key: _keyToken);
    }
  }

  // Recuperar la sesión almacenada.
  Future<UsuarioSesion?> restaurarSesion() async {
  final usuarioGuardado = await _storage.read(key: _keyUsuario);
  final tokenGuardado = await _storage.read(key: _keyToken);

  if (usuarioGuardado == null || tokenGuardado == null) {
    await cerrarSesion();
    return null;
  }

  // Recuperar los datos del usuario.
  try {
    final datos = jsonDecode(usuarioGuardado) as Map<String, dynamic>;
    final usuario = UsuarioSesion.fromJson(datos);

    // Comprobar el JWT mediante una ruta protegida del backend.
    await ApiService.get(
      '/api/prueba/privada',
      token: tokenGuardado,
    );

    // Solo restaurar la sesión después de validar el token.
    _usuario = usuario;
    _token = tokenGuardado;

    return _usuario;
  } catch (e) {
    final mensaje = e.toString();

    // Si el backend rechaza el token, cerrar la sesión.
    if (mensaje.contains('401') || mensaje.contains('403')) {
      await cerrarSesion();
      return null;
    }

    // Si hay un problema de conexión, no borrar el token.
    rethrow;
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
