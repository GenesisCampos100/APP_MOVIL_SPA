import 'package:flutter/foundation.dart';
import '../../features/auth/auth_state.dart';
import '../models/empleado.dart';
import '../models/servicio.dart';

/// DATOS DE PRUEBA (mock) en memoria, separados por usuario.
/// Tablas de la base de datos:
///   favoritos_servicios (id_cliente, id_servicio, fecha)
///   favoritos_empleados (id_cliente, id_empleado, fecha)
///
/// Con la API sería:
///   servicios / empleados -> GET    /favoritos/servicios  y  /favoritos/empleados
///   agregar               -> POST   /favoritos/servicios/:id  y  /favoritos/empleados/:id
///   quitar                -> DELETE /favoritos/servicios/:id  y  /favoritos/empleados/:id
///   corazones al iniciar  -> GET    /favoritos/ids
///
/// Se guarda el objeto completo (Servicio / Empleado) para poder mostrarlo en
/// la lista de Favoritos sin pedirlo otra vez, y para no tener que agregar
/// un campo "esFavorito" a los modelos.
class FavoritosRepository extends ChangeNotifier {
  FavoritosRepository._();
  static final FavoritosRepository instance = FavoritosRepository._();

  // En cada mapa, el orden de inserción = del más antiguo al más reciente.
  final Map<String, Map<int, Servicio>> _servicios = {};
  final Map<String, Map<int, Empleado>> _empleados = {};

  String get _clave => AuthState.instance.usuario?.correo ?? '';

  bool esFavoritoServicio(int id) => _servicios[_clave]?.containsKey(id) ?? false;
  bool esFavoritoEmpleado(int id) => _empleados[_clave]?.containsKey(id) ?? false;

  /// Más recientes primero.
  List<Servicio> get servicios =>
      (_servicios[_clave]?.values.toList() ?? <Servicio>[]).reversed.toList();

  /// Más recientes primero.
  List<Empleado> get empleados =>
      (_empleados[_clave]?.values.toList() ?? <Empleado>[]).reversed.toList();

  /// Agrega o quita un servicio. Devuelve true si quedó como favorito.
  bool alternarServicio(Servicio s) {
    final mapa = _servicios.putIfAbsent(_clave, () => <int, Servicio>{});
    final quedaFavorito = !mapa.containsKey(s.id);
    if (quedaFavorito) {
      mapa[s.id] = s;
    } else {
      mapa.remove(s.id);
    }
    notifyListeners();
    return quedaFavorito;
  }

  /// Agrega o quita un empleado. Devuelve true si quedó como favorito.
  bool alternarEmpleado(Empleado e) {
    if (e.esCualquiera) return false;
    final mapa = _empleados.putIfAbsent(_clave, () => <int, Empleado>{});
    final quedaFavorito = !mapa.containsKey(e.id);
    if (quedaFavorito) {
      mapa[e.id] = e;
    } else {
      mapa.remove(e.id);
    }
    notifyListeners();
    return quedaFavorito;
  }
}
