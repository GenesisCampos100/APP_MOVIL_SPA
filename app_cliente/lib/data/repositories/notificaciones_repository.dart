import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';

/// DATOS DE PRUEBA (mock) en memoria. Con la API sería:
///   items              -> GET    /notificaciones
///   marcarLeida        -> PUT    /notificaciones/:id/leida
///   marcarTodasLeidas  -> PUT    /notificaciones/leidas
///   eliminar           -> DELETE /notificaciones/:id
///   limpiarTodo        -> DELETE /notificaciones
///   confirmarAsistencia-> PUT    /citas/:id/confirmar
class NotificacionesRepository extends ChangeNotifier {
  NotificacionesRepository._() {
    _items.addAll(_ejemplo());
  }
  static final NotificacionesRepository instance = NotificacionesRepository._();

  final List<Notificacion> _items = [];
  int _siguienteId = 100;

  /// Un ejemplo de cada etapa de una cita.
  static List<Notificacion> _ejemplo() {
    final ahora = DateTime.now();
    return [
      Notificacion(
        id: 1,
        idCita: 101,
        tipo: Notificacion.confirmarCita,
        titulo: 'Confirma tu cita',
        mensaje:
            'Tu cita de Facial hidratante es mañana a las 2:30 pm. Confírmala o se cancelará automáticamente.',
        fechaEnvio: ahora.subtract(const Duration(hours: 2)),
      ),
      Notificacion(
        id: 2,
        idCita: 100,
        tipo: Notificacion.citaConfirmada,
        titulo: 'Cita confirmada',
        mensaje: 'Tu cita de Masaje relajante quedó confirmada. ¡Te esperamos en Aura Spa!',
        fechaEnvio: ahora.subtract(const Duration(days: 1)),
        leida: true,
      ),
      Notificacion(
        id: 3,
        idCita: 100,
        tipo: Notificacion.citaCreada,
        titulo: 'Cita registrada',
        mensaje:
            'Tu cita de Masaje relajante quedó registrada. Recuerda confirmarla 24 horas antes.',
        fechaEnvio: ahora.subtract(const Duration(days: 2)),
        leida: true,
      ),
      Notificacion(
        id: 4,
        idCita: 102,
        tipo: Notificacion.citaCancelada,
        titulo: 'Cita cancelada',
        mensaje:
            'Tu cita de Pedicure Spa se canceló porque no la confirmaste a tiempo. El horario quedó libre.',
        fechaEnvio: ahora.subtract(const Duration(days: 4)),
        leida: true,
      ),
      Notificacion(
        id: 5,
        idCita: 1,
        tipo: Notificacion.resena,
        titulo: '¿Cómo estuvo tu servicio?',
        mensaje: 'Cuéntanos tu experiencia con tu Masaje relajante escribiendo una reseña.',
        fechaEnvio: ahora.subtract(const Duration(days: 5)),
        leida: true,
      ),
    ];
  }

  /// Más recientes primero.
  List<Notificacion> get items {
    final copia = [..._items];
    copia.sort((a, b) => b.fechaEnvio.compareTo(a.fechaEnvio));
    return copia;
  }

  int get noLeidas => _items.where((n) => !n.leida).length;

  /// ¿Hay alguna "Confirma tu cita" sin atender?
  bool get hayPendientes => _items.any((n) => n.requiereAccion);

  void marcarLeida(int id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].leida) return;
    _items[i] = _items[i].copyWith(leida: true);
    notifyListeners();
  }

  void marcarTodasLeidas() {
    if (noLeidas == 0) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(leida: true);
    }
    notifyListeners();
  }

  void eliminar(int id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Para "Deshacer" después de eliminar una.
  void restaurar(Notificacion n) {
    _items.add(n);
    notifyListeners();
  }

  /// Borra todas, menos las que todavía piden confirmar una cita.
  void limpiarTodo() {
    _items.removeWhere((n) => !n.requiereAccion);
    notifyListeners();
  }

  /// El usuario confirma su asistencia desde "Confirma tu cita".
  /// Se marca como atendida y llega la notificación "Cita confirmada".
  void confirmarAsistencia(int id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final original = _items[i];
    _items[i] = original.copyWith(leida: true, atendida: true);
    _items.add(Notificacion(
      id: _siguienteId++,
      idCita: original.idCita,
      tipo: Notificacion.citaConfirmada,
      titulo: 'Cita confirmada',
      mensaje: 'Confirmaste tu cita. ¡Te esperamos en Aura Spa!',
      fechaEnvio: DateTime.now(),
    ));
    notifyListeners();
  }
}
