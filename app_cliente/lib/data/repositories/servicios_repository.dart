
import '../models/servicio.dart';
import '../services/api_service.dart';
import '../services/sesion_service.dart';
import '../models/resenas_servicio.dart';

class ServiciosRepository {
  // Obtener todos los servicios del catálogo.
  Future<List<Servicio>> obtenerServicios() async {
    final data = await ApiService.get('/api/servicios');

    final lista = data as List;

    return lista
        .map(
          (json) => Servicio.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // Obtener los servicios más populares del mes.
  Future<List<Servicio>> obtenerServiciosDestacados() async {
    final data = await ApiService.get('/api/servicios/destacados');

    final lista = data as List;

    return lista
        .map(
          (json) => Servicio.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // Publicar una reseña de una cita completada.
  Future<Map<String, dynamic>> publicarResena({
    required int idServicio,
    required int idCita,
    required int calificacion,
    String? comentario,
    List<String> aspectos = const [],
  }) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.token == null) {
      throw Exception(
        'Debes iniciar sesión para publicar una reseña.',
      );
    }

    if (calificacion < 1 || calificacion > 5) {
      throw Exception('Selecciona una calificación entre 1 y 5.');
    }

    try {
      final data = await ApiService.post(
        '/api/servicios/$idServicio/resenas',
        {
          'id_cita': idCita,
          'calificacion': calificacion,
          'comentario': comentario?.trim() ?? '',
          'aspectos': aspectos,
        },
        token: sesion.token,
      );

      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('No se pudo publicar la reseña: $e');
    }
  }


  // Obtener reseñas y promedios de un servicio.
  Future<ResenasServicio> obtenerResenasPorServicio(
    int idServicio,
  ) async {
    try {
      final data = await ApiService.get(
        '/api/servicios/$idServicio/resenas',
      );

      return ResenasServicio.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      throw Exception('No se pudieron obtener las reseñas: $e');
    }
  }


}
