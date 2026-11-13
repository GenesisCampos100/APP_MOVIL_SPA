import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/models/puesto_model.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Operaciones administrativas; todas requieren JWT de Administrador.
class EmpleadosRepository {
  final ApiClient _client;

  EmpleadosRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<EmployeeModel>> obtenerEmpleados() async {
    final respuesta = await _client.get('/admin/empleados');
    if (respuesta is! List) {
      throw ApiException(message: 'La API no devolvió una lista de empleados.');
    }
    return respuesta.map((item) {
      if (item is! Map) {
        throw ApiException(message: 'La API devolvió un empleado inválido.');
      }
      final empleado = EmployeeModel.fromJson(Map<String, dynamic>.from(item));
      if (empleado.idEmpleado.isEmpty || empleado.nombreCompleto.isEmpty) {
        throw ApiException(message: 'La API devolvió un empleado incompleto.');
      }
      return empleado;
    }).toList();
  }

  Future<List<PuestoModel>> obtenerPuestos() async {
    final respuesta = await _client.get('/admin/empleados/puestos');
    if (respuesta is! List) {
      throw ApiException(message: 'La API no devolvió los puestos.');
    }
    return respuesta.map((item) {
      if (item is! Map) throw ApiException(message: 'Puesto inválido.');
      return PuestoModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> crearEmpleado(Map<String, dynamic> datos) async {
    await _client.post('/admin/empleados', body: datos);
  }

  Future<void> editarEmpleado(String id, Map<String, dynamic> datos) async {
    await _client.put('/admin/empleados/$id', body: datos);
  }

  Future<void> cambiarEstado(String id, {required bool activo}) async {
    await _client.put('/admin/empleados/$id/estado', body: {'estado': activo});
  }
}
