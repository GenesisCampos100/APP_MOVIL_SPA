import '../models/usuario_sesion.dart';

class SesionService {
  SesionService._();

  static final SesionService instance = SesionService._();

  UsuarioSesion? _usuario;

  UsuarioSesion? get usuario => _usuario;

  bool get estaIniciada => _usuario != null;

  int? get idCliente => _usuario?.idCliente;

  void iniciarSesion(UsuarioSesion usuario) {
    _usuario = usuario;
  }

  void cerrarSesion() {
    _usuario = null;
  }
}