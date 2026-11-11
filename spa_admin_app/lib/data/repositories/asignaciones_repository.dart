import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Gestiona la tabla empleado_servicios mediante endpoints administrativos.
class AsignacionesRepository {
  final ApiClient _client;
  AsignacionesRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, Set<String>>> obtenerAsignaciones() async {
    final respuesta = await _client.get('/admin/empleados/asignaciones');
    if (respuesta is! List) {
      throw ApiException(message: 'Formato inesperado de asignaciones.');
    }
    final mapa = <String, Set<String>>{};
    for (final elemento in respuesta) {
      if (elemento is! Map) {
        throw ApiException(message: 'Una asignación tiene formato incorrecto.');
      }
      final empleado = elemento['id_empleado']?.toString() ?? '';
      final servicio = elemento['id_servicio']?.toString() ?? '';
      if (int.tryParse(empleado) == null || int.tryParse(servicio) == null) {
        throw ApiException(message: 'Una asignación contiene identificadores inválidos.');
      }
      mapa.putIfAbsent(empleado, () => <String>{}).add(servicio);
    }
    return mapa;
  }

  Future<void> guardarAsignaciones(String idEmpleado, Set<String> servicios) async {
    final empleado = int.tryParse(idEmpleado);
    final ids = servicios.map(int.tryParse).toList();
    if (empleado == null || empleado <= 0 || ids.any((id) => id == null || id <= 0)) {
      throw const FormatException('Hay identificadores de empleado o servicio inválidos.');
    }
    await _client.put(
      '/admin/empleados/$empleado/asignaciones',
      body: {'id_servicios': ids.cast<int>()..sort()},
    );
  }
}
