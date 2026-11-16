
import '../models/servicio.dart';
import '../services/api_service.dart';

class ServiciosRepository {
  // Obtener todos los servicios del catálogo
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

  // Obtener los 5 servicios más populares del mes
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
}
