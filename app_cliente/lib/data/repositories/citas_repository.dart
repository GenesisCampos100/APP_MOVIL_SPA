import 'package:flutter/foundation.dart';
import '../models/cita.dart';
import '../models/empleado.dart';
import '../models/servicio.dart';
import 'empleados_repository.dart';

/// Pon en false para ocultar la cita completada de ejemplo en "Mis citas".
const bool kMostrarCitasDemo = true;

/// DATOS DE PRUEBA (mock) guardados en memoria. Con la API:
///   citasDe -> GET  /citas        (las del cliente con sesión)
///   crear   -> POST /citas        (ver Cita.nueva)
class CitasRepository extends ChangeNotifier {
  CitasRepository._();
  static final CitasRepository instance = CitasRepository._();

  final Map<String, List<Cita>> _porCorreo = {};
  int _siguienteId = 100;

  /// Cita completada de ejemplo, para ver el botón "Escribir reseña".
  static final Cita _demo = Cita(
    id: 1,
    idCliente: 0,
    idEmpleado: 2,
    idServicio: 1,
    fecha: DateTime(2026, 9, 11),
    horaInicio: '11:30',
    duracionAplicada: 45,
    precioAplicado: 500,
    estado: Cita.completada,
    servicioNombre: 'Masaje relajante',
    servicioCategoria: 'Corporal',
    empleadoNombre: 'Vanessa',
  );

  List<Cita> citasDe(String correo) => [
        if (kMostrarCitasDemo) _demo,
        ...?_porCorreo[correo],
      ];

  Future<Cita> crear({
    required String correo,
    required Servicio servicio,
    required Empleado empleado,
    required DateTime fecha,
    required String hora,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // "Cualquier disponible": se asigna al primero de la lista.
    var asignado = empleado;
    if (empleado.esCualquiera) {
      final lista = await EmpleadosRepository().obtenerParaServicio(servicio.id);
      asignado = lista.first;
    }

    final cita = Cita(
      id: _siguienteId++,
      idCliente: 0,
      idEmpleado: asignado.id,
      idServicio: servicio.id,
      fecha: fecha,
      horaInicio: hora,
      duracionAplicada: servicio.minutos,
      precioAplicado: servicio.precio,
      estado: Cita.confirmada,
      servicioNombre: servicio.nombre,
      servicioCategoria: servicio.categoria,
      empleadoNombre: asignado.nombre,
    );
    (_porCorreo[correo] ??= []).add(cita);
    notifyListeners();
    return cita;
  }
}
