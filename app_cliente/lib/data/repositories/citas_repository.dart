
import 'package:flutter/foundation.dart';

import '../models/cita.dart';
import '../models/empleado.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';
import '../services/sesion_service.dart';

class CitasRepository extends ChangeNotifier {
  CitasRepository._();

  static final CitasRepository instance = CitasRepository._();

  /// Obtiene las citas del cliente actualmente iniciado.
  Future<List<Cita>> obtenerMisCitas() async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada) {
      throw Exception('Debes iniciar sesión para consultar tus citas');
    }

    final idCliente = sesion.idCliente;
    final token = sesion.token;

    if (idCliente == null || token == null) {
      throw Exception('La sesión no tiene los datos necesarios');
    }

    try {
      final data = await ApiService.get(
        '/api/citas/cliente/$idCliente',
        token: token,
      );

      final lista = data['citas'] as List<dynamic>;

      return lista
          .map(
            (json) => Cita.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('No se pudieron cargar tus citas: $e');
    }
  }

  /// Aparta temporalmente un horario durante cinco minutos.
  ///
  /// Devuelve la respuesta del backend, incluyendo:
  /// - reserva
  /// - empleado asignado
  Future<Map<String, dynamic>> apartarHorario({
    required Servicio servicio,
    required Empleado empleado,
    required DateTime fecha,
    required String hora,
  }) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.token == null) {
      throw Exception('Debes iniciar sesión para apartar un horario');
    }

    try {
      final data = await ApiService.post(
        '/api/citas/apartar',
        {
          'id_servicio': servicio.id,
          'id_empleado': empleado.id,
          'fecha': fecha.toIso8601String().split('T').first,
          'hora_inicio': hora,
        },
        token: sesion.token,
      );

      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('No se pudo apartar el horario: $e');
    }
  }

  /// Cancela un apartado temporal del cliente.
  Future<void> cancelarApartado(int idReserva) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.token == null) {
      throw Exception('Debes iniciar sesión para cancelar el apartado');
    }

    try {
      await ApiService.delete(
        '/api/citas/apartar/$idReserva',
        token: sesion.token,
      );
    } catch (e) {
      throw Exception('No se pudo cancelar el apartado: $e');
    }
  }

  /// Confirma un apartado y registra la cita definitiva.
  Future<Cita> confirmarApartado({
    required int idReserva,
    String? observaciones,
  }) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.token == null) {
      throw Exception('Debes iniciar sesión para confirmar la cita');
    }

    try {
      final data = await ApiService.post(
        '/api/citas/confirmar-apartado',
        {
          'id_reserva': idReserva,
          if (observaciones != null &&
              observaciones.trim().isNotEmpty)
            'observaciones': observaciones.trim(),
        },
        token: sesion.token,
      );

      final citaJson = data['cita'] as Map<String, dynamic>;

      final cita = Cita.fromJson(citaJson);

      notifyListeners();

      return cita;
    } catch (e) {
      throw Exception('No se pudo confirmar la cita: $e');
    }
  }

  /// GET /api/citas/disponibilidad
  Future<List<String>> obtenerDisponibilidad({
    required int idServicio,
    required DateTime fecha,
  }) async {
    final fechaTexto =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    final data = await ApiService.get(
      '/api/citas/disponibilidad'
      '?id_servicio=$idServicio&fecha=$fechaTexto',
    );

    final horarios = data['horarios'];

    if (horarios is! List) {
      throw Exception('La respuesta de disponibilidad no es válida.');
    }

    return horarios.map((hora) => hora.toString()).toList();
  }

  /// Método anterior de registro directo.
  /// Se conserva temporalmente por compatibilidad.
  Future<Cita> crear({
    required Servicio servicio,
    required Empleado empleado,
    required DateTime fecha,
    required String hora,
    String? observaciones,
  }) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada || sesion.idCliente == null ||
        sesion.token == null) {
      throw Exception('Debes iniciar sesión para registrar una cita');
    }

    final data = await ApiService.post(
      '/api/citas',
      {
        'id_cliente': sesion.idCliente,
        'id_servicio': servicio.id,
        'id_empleado': empleado.id,
        'fecha': fecha.toIso8601String().split('T').first,
        'hora_inicio': hora,
        if (observaciones != null) 'observaciones': observaciones,
      },
      token: sesion.token,
    );

    final citaJson = data['cita'] as Map<String, dynamic>;
    final cita = Cita.fromJson(citaJson);

    notifyListeners();

    return cita;
  }
}
