import '../models/servicio.dart';
import '../services/api_service.dart';


class ServiciosRepository {
  Future<List<Servicio>> obtenerServicios() async {
    final data = await ApiService.get('/api/servicios'); //cambiar a /servicios

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

