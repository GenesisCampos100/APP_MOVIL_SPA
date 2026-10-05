import '../models/resena.dart';

/// DATOS DE PRUEBA (mock). Solo el servicio 1 (Masaje relajante) tiene
/// reseñas de ejemplo; los demás no tienen ninguna.
/// Con la API sería: GET /servicios/:id/resenas
///
/// Las calificaciones del servicio y del profesional son distintas a
/// propósito, y Vanessa tiene dos reseñas, para ver cómo funciona el filtro.
class ResenasRepository {
  Future<List<Resena>> obtenerDeServicio(int idServicio) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (idServicio != 1) return [];

    final ahora = DateTime.now();
    return [
      Resena(
        id: 1, idCita: 1,
        calificacionServicio: 5, calificacionEmpleado: 5,
        comentario: 'La mejor experiencia de spa que he tenido. Instalaciones impecables y trato profesional.',
        fecha: ahora.subtract(const Duration(days: 35)),
        autor: 'María Rojas', empleadoNombre: 'Vanessa', servicioCategoria: 'Corporal',
      ),
      Resena(
        id: 2, idCita: 2,
        calificacionServicio: 5, calificacionEmpleado: 4,
        comentario: 'Excelente masaje, me quitó por completo la tensión de la espalda. Muy recomendado.',
        fecha: ahora.subtract(const Duration(days: 150)),
        autor: 'Juan Gómez', empleadoNombre: 'Zinedine', servicioCategoria: 'Corporal',
      ),
      Resena(
        id: 3, idCita: 3,
        calificacionServicio: 4, calificacionEmpleado: 5,
        comentario: 'Excelente técnica y atención. Solo tardaron un poco en recepción, pero valió la pena.',
        fecha: ahora.subtract(const Duration(days: 40)),
        autor: 'Ana Torres', empleadoNombre: 'Vanessa', servicioCategoria: 'Corporal',
      ),
    ];
  }
}
