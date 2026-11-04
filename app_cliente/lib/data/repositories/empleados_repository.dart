import '../models/empleado.dart';
import '../services/api_service.dart';

class EmpleadosRepository {
  Future<List<Empleado>> obtenerParaServicio(int idServicio) async {
    final data = await ApiService.get(
      '/api/servicios/$idServicio/empleados', //cambiar a /servicios/{idServicio}/empleados
    );

    final empleadosJson = data['empleados'] as List;

    return empleadosJson
        .map(
          (json) => Empleado.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}