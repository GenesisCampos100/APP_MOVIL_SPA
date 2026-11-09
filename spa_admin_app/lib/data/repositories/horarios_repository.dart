import 'package:spa_admin_app/data/models/horario_semanal_model.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Todas las operaciones pasan por la API autenticada, nunca directamente
/// por la base de datos.
class HorariosRepository {
  final ApiClient _client;

  HorariosRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<EmpleadoConHorarios>> obtenerHorarios() async {
    final respuesta = await _client.get('/admin/horarios');
    if (respuesta is! List) {
      throw ApiException(message: 'No fue posible consultar los horarios.');
    }
    return respuesta.map((item) {
      if (item is! Map) {
        throw ApiException(message: 'La información de horarios es inválida.');
      }
      final empleado = EmpleadoConHorarios.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (empleado.idEmpleado <= 0 || empleado.nombre.isEmpty) {
        throw ApiException(message: 'La información del personal está incompleta.');
      }
      return empleado;
    }).toList(growable: false);
  }

  Future<void> crearHorario({
    required int idEmpleado,
    required String diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    await _client.post('/admin/horarios', body: {
      'id_empleado': idEmpleado,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
  }

  /// Registra uno o varios días con las mismas horas en una sola transacción.
  /// Si alguno entra en conflicto, el servidor no guarda ningún turno.
  Future<void> crearHorariosVarios({
    required int idEmpleado,
    required List<String> diasSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    await _client.post('/admin/horarios/lote', body: {
      'id_empleado': idEmpleado,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
  }

  Future<void> editarHorario({
    required int idHorario,
    required String diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    await _client.put('/admin/horarios/$idHorario', body: {
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
  }

  Future<void> eliminarHorario(int idHorario) async {
    await _client.delete('/admin/horarios/$idHorario');
  }
}
