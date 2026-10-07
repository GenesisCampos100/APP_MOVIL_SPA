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
  /// Obtiene las citas del cliente actualmente iniciado.
Future<List<Cita>> obtenerMisCitas() async {
  final sesion = SesionService.instance;

  if (!sesion.estaIniciada) {
    throw Exception('Debes iniciar sesión para consultar tus citas');
  }

  final idCliente = sesion.idCliente;

  if (idCliente == null) {
    throw Exception('La sesión no tiene un cliente asociado');
  }

  try {
    final data = await ApiService.get(
      '/citas/cliente/$idCliente',
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

  /// Registra una nueva cita en el backend.
  Future<Cita> crear({
    required Servicio servicio,
    required Empleado empleado,
    required DateTime fecha,
    required String hora,
    String? observaciones,
  }) async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada) {
      throw Exception('Debes iniciar sesión para registrar una cita');
    }

    final idCliente = sesion.idCliente;

    if (idCliente == null) {
      throw Exception('La sesión no tiene un cliente asociado');
    }

    final data = await ApiService.post(
      '/citas',
      {
        'id_cliente': idCliente,
        'id_servicio': servicio.id,
        'id_empleado': empleado.id,
        'fecha': fecha.toIso8601String().split('T').first,
        'hora_inicio': hora,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );

    final citaJson = data['cita'] as Map<String, dynamic>;

    final cita = Cita.fromJson(citaJson);

    notifyListeners();

    return cita;
  }
}