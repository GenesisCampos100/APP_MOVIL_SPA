
import 'package:flutter/foundation.dart';

import '../../data/models/empleado.dart';
import '../../data/models/servicio.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sesion_service.dart';

class FavoritosRepository extends ChangeNotifier {
  FavoritosRepository._();

  static final FavoritosRepository instance = FavoritosRepository._();

  final Map<int, Servicio> _servicios = {};
  final Map<int, Empleado> _empleados = {};

  final Set<int> _idsServicios = {};
  final Set<int> _idsEmpleados = {};

  bool _cargando = false;
  bool get cargando => _cargando;

  String? get _token => SesionService.instance.token;

  bool get _tieneSesion =>
      SesionService.instance.estaIniciada && _token != null;

  bool esFavoritoServicio(int id) => _idsServicios.contains(id);

  bool esFavoritoEmpleado(int id) => _idsEmpleados.contains(id);

  List<Servicio> get servicios => _servicios.values.toList().reversed.toList();

  List<Empleado> get empleados => _empleados.values.toList().reversed.toList();

  /// Carga únicamente los IDs para mostrar los corazones en el catálogo.
  Future<void> cargarIds() async {
    if (!_tieneSesion) {
      limpiar();
      return;
    }

    final respuesta = await ApiService.get(
      '/api/favoritos/ids',
      token: _token,
    );

    final idsServicios = (respuesta['servicios'] as List)
        .map((id) => (id as num).toInt())
        .toSet();

    final idsEmpleados = (respuesta['empleados'] as List)
        .map((id) => (id as num).toInt())
        .toSet();

    _idsServicios
      ..clear()
      ..addAll(idsServicios);

    _idsEmpleados
      ..clear()
      ..addAll(idsEmpleados);

    // Quitar objetos que ya no son favoritos.
    _servicios.removeWhere((id, _) => !_idsServicios.contains(id));
    _empleados.removeWhere((id, _) => !_idsEmpleados.contains(id));

    notifyListeners();
  }

  /// Carga los objetos completos para la pantalla de favoritos.
  Future<void> cargarFavoritos() async {
    if (!_tieneSesion) {
      limpiar();
      return;
    }

    _cargando = true;
    notifyListeners();

    try {
      final respuestas = await Future.wait([
        ApiService.get('/api/favoritos/servicios', token: _token),
        ApiService.get('/api/favoritos/empleados', token: _token),
      ]);

      final listaServicios = (respuestas[0]['servicios'] as List)
          .map((json) => Servicio.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();

      final listaEmpleados = (respuestas[1]['empleados'] as List)
          .map((json) => Empleado.fromJson(
                Map<String, dynamic>.from(json),
              ))
          .toList();

      _servicios
        ..clear()
        ..addEntries(listaServicios.map((s) => MapEntry(s.id, s)));

      _empleados
        ..clear()
        ..addEntries(listaEmpleados.map((e) => MapEntry(e.id, e)));

      _idsServicios
        ..clear()
        ..addAll(_servicios.keys);

      _idsEmpleados
        ..clear()
        ..addAll(_empleados.keys);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Agrega o quita un servicio en PostgreSQL.
  /// Devuelve true si quedó como favorito.
  Future<bool> alternarServicio(Servicio servicio) async {
    if (!_tieneSesion) {
      throw Exception('Debes iniciar sesión para guardar favoritos');
    }

    final id = servicio.id;
    final quitar = _idsServicios.contains(id);

    if (quitar) {
      await ApiService.delete(
        '/api/favoritos/servicios/$id',
        token: _token,
      );

      _idsServicios.remove(id);
      _servicios.remove(id);
    } else {
      await ApiService.post(
        '/api/favoritos/servicios/$id',
        {},
        token: _token,
      );

      _idsServicios.add(id);
      _servicios[id] = servicio;
    }

    notifyListeners();
    return !quitar;
  }

  /// Agrega o quita un empleado en PostgreSQL.
  /// Devuelve true si quedó como favorito.
  Future<bool> alternarEmpleado(Empleado empleado) async {
    if (empleado.esCualquiera) return false;

    if (!_tieneSesion) {
      throw Exception('Debes iniciar sesión para guardar favoritos');
    }

    final id = empleado.id;
    final quitar = _idsEmpleados.contains(id);

    if (quitar) {
      await ApiService.delete(
        '/api/favoritos/empleados/$id',
        token: _token,
      );

      _idsEmpleados.remove(id);
      _empleados.remove(id);
    } else {
      await ApiService.post(
        '/api/favoritos/empleados/$id',
        {},
        token: _token,
      );

      _idsEmpleados.add(id);
      _empleados[id] = empleado;
    }

    notifyListeners();
    return !quitar;
  }

  /// Limpia los datos locales al cerrar sesión.
  void limpiar() {
    _servicios.clear();
    _empleados.clear();
    _idsServicios.clear();
    _idsEmpleados.clear();

    _cargando = false;
    notifyListeners();
  }
}
