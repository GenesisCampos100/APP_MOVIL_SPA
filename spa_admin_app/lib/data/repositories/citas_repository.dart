import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Acceso a las citas reales de SpaBackend.
/// El backend filtra por rol e identidad a partir del JWT.
class CitasRepository {
  final ApiClient _client;

  CitasRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<AppointmentModel>> obtenerCitas() async {
    final respuesta = await _client.get('/citas');

    if (respuesta is! Map<String, dynamic> || respuesta['citas'] is! List) {
      throw ApiException(message: 'La API devolvió un formato de citas inesperado.');
    }

    final citas = (respuesta['citas'] as List).map((elemento) {
      if (elemento is! Map) {
        throw ApiException(message: 'Una cita tiene un formato incorrecto.');
      }
      final dato = Map<String, dynamic>.from(elemento);

      // pg envía DATE habitualmente como '2026-11-09T00:00:00.000Z'.
      // Se toma solo la fecha civil para no desplazarla por zona horaria.
      final fechaTexto = (dato['fecha'] ?? '').toString();
      if (fechaTexto.length < 10) {
        throw ApiException(message: 'Una cita no contiene fecha válida.');
      }
      final fecha = DateTime.tryParse(fechaTexto.substring(0, 10));
      if (fecha == null) {
        throw ApiException(message: 'Una cita no contiene fecha válida.');
      }
      final horaTexto = (dato['hora_inicio'] ?? '').toString();

      return AppointmentModel(
        idCita: '#Cita-${dato['id_cita'] ?? '—'}',
        idCliente: '#CLI-${dato['id_cliente'] ?? '—'}',
        nombreCliente: (dato['cliente'] ?? 'Sin nombre').toString(),
        nombreServicio: (dato['servicio'] ?? 'Sin servicio').toString(),
        nombreEmpleado: (dato['empleado'] ?? 'Sin especialista').toString(),
        precioAplicado: double.tryParse('${dato['precio_aplicado'] ?? 0}') ?? 0.0,
        fecha: fecha,
        horaInicio: horaTexto.length >= 5 ? horaTexto.substring(0, 5) : horaTexto,
        duracionAplicada: '${dato['duracion_aplicada'] ?? 0} min',
        estado: (dato['estado'] ?? 'Pendiente').toString(),
        observaciones: dato['observaciones']?.toString(),
      );
    }).toList();

    citas.sort((a, b) {
      final porFecha = a.fecha.compareTo(b.fecha);
      return porFecha != 0 ? porFecha : a.horaInicio.compareTo(b.horaInicio);
    });
    return citas;
  }
}
