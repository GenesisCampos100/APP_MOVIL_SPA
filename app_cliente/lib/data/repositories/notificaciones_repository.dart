
import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';
import '../services/sesion_service.dart';
import 'citas_repository.dart';

class NotificacionesRepository extends ChangeNotifier {
  NotificacionesRepository._();

  static final NotificacionesRepository instance =
      NotificacionesRepository._();

  final List<Notificacion> _items = [];

  bool _cargando = false;
  String? errorCarga;

  bool get cargando => _cargando;

  // Más recientes primero.
  List<Notificacion> get items {
    final copia = [..._items];
    copia.sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
    return copia;
  }

  int get noLeidas => _items.where((n) => !n.leida).length;

  bool get hayPendientes => _items.any((n) => n.requiereAccion);

  // Obtener notificaciones reales del usuario autenticado.
  Future<void> cargar() async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.token == null) {
      throw Exception('Debes iniciar sesión para ver tus notificaciones.');
    }

    _cargando = true;
    errorCarga = null;
    notifyListeners();

    try {
      final respuesta = await ApiService.get(
        '/api/notificaciones',
        token: sesion.token,
      );

      if (respuesta is! List) {
        throw FormatException(
          'La respuesta de notificaciones no tiene el formato esperado.',
        );
      }

      final notificaciones = respuesta.map((item) {
        return Notificacion.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      _items
        ..clear()
        ..addAll(notificaciones);
    } catch (e) {
      errorCarga = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Acciones locales temporales: después se conectarán al backend.
  Future<void> marcarLeida(int id) async {
    final i = _items.indexWhere((n) => n.id == id);

    if (i == -1 || _items[i].leida) return;

    final token = SesionService.instance.token;

    if (token == null) {
      throw Exception('No hay una sesión activa.');
    }

    await ApiService.patch(
      '/api/notificaciones/$id/leida',
      token: token,
    );

    _items[i] = _items[i].copyWith(leida: true);

    notifyListeners();
  }

  Future<void> marcarTodasLeidas() async {
    if (_items.every((n) => n.leida)) return;

    final token = SesionService.instance.token;

    if (token == null) {
      throw Exception('No hay una sesión activa.');
    }

    await ApiService.patch(
      '/api/notificaciones/leidas',
      token: token,
    );

    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(leida: true);
    }

    notifyListeners();
  }

  void eliminar(int id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void restaurar(Notificacion n) {
    _items.add(n);
    notifyListeners();
  }

  void limpiarTodo() {
    _items.removeWhere((n) => !n.requiereAccion);
    notifyListeners();
  }

  
  Future<void> confirmarAsistencia(int id) async {
    final i = _items.indexWhere((n) => n.id == id);

    if (i == -1) {
      throw Exception('No se encontró la notificación.');
    }

    final notificacion = _items[i];

    if (!notificacion.requiereAccion) {
      throw Exception('Esta notificación ya no requiere confirmación.');
    }

    final idCita = notificacion.idCita;

    if (idCita == null) {
      throw Exception('La notificación no tiene una cita asociada.');
    }

    // Confirmar la cita realmente en el backend.
    await CitasRepository.instance.confirmarCita(idCita);

    // Actualizar la notificación en memoria.
    _items[i] = notificacion.copyWith(
      leida: true,
      atendida: true,
    );

    notifyListeners();
  }

}
