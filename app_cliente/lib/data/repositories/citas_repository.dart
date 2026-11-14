import 'package:flutter/foundation.dart';
import '../models/cita.dart';
import '../models/empleado.dart';
import '../models/servicio.dart';
import 'empleados_repository.dart';

/// Pon en false para ocultar las citas de ejemplo en "Mis citas".
const bool kMostrarCitasDemo = true;

/// DATOS DE PRUEBA (mock) guardados en memoria. Con la API:
///   citasDe  -> GET /citas
///   crear    -> POST /citas
///   cancelar -> PUT /citas/:id/cancelar
class CitasRepository extends ChangeNotifier {
  CitasRepository._();
  static final CitasRepository instance = CitasRepository._();

  final Map<String, List<Cita>> _porCorreo = {};
  final Set<int> _demoCanceladas = {};
  int _siguienteId = 100;

  /// Cita completada de ejemplo, para ver el botón "Escribir reseña".
  static final Cita _completada = Cita(
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

  Cita _conEstado(Cita c, String estado) => Cita(
        id: c.id,
        idCliente: c.idCliente,
        idEmpleado: c.idEmpleado,
        idServicio: c.idServicio,
        fecha: c.fecha,
        horaInicio: c.horaInicio,
        duracionAplicada: c.duracionAplicada,
        precioAplicado: c.precioAplicado,
        estado: estado,
        observaciones: c.observaciones,
        servicioNombre: c.servicioNombre,
        servicioCategoria: c.servicioCategoria,
        empleadoNombre: c.empleadoNombre,
      );

  /// Citas de ejemplo. Las fechas se calculan a partir de hoy para que
  /// siempre haya una con botones activos y otra con botones desactivados.
  List<Cita> _citasDemo() {
    final ahora = DateTime.now();
    final pronto = ahora.add(const Duration(hours: 5)); // menos de 24 h
    final enTresDias = DateTime(ahora.year, ahora.month, ahora.day).add(const Duration(days: 3));
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final lista = [
      _completada,
      Cita(
        id: 2,
        idCliente: 0,
        idEmpleado: 1,
        idServicio: 2,
        fecha: enTresDias,
        horaInicio: '11:30',
        duracionAplicada: 45,
        precioAplicado: 900,
        estado: Cita.confirmada,
        servicioNombre: 'Facial hidratante',
        servicioCategoria: 'Facial',
        empleadoNombre: 'Zinedine',
      ),
      Cita(
        id: 3,
        idCliente: 0,
        idEmpleado: 3,
        idServicio: 5,
        fecha: DateTime(pronto.year, pronto.month, pronto.day),
        horaInicio: hhmm(pronto),
        duracionAplicada: 50,
        precioAplicado: 600,
        estado: Cita.confirmada,
        servicioNombre: 'Pedicure Spa',
        servicioCategoria: 'Pedicure',
        empleadoNombre: 'Mario',
      ),
    ];
    return lista
        .map((c) => _demoCanceladas.contains(c.id) ? _conEstado(c, Cita.cancelada) : c)
        .toList();
  }

  List<Cita> citasDe(String correo) => [
        if (kMostrarCitasDemo) ..._citasDemo(),
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

  /// Cancela una cita: pasa al estado "Cancelada".
  void cancelar(String correo, int id) {
    final propias = _porCorreo[correo];
    if (propias != null) {
      final i = propias.indexWhere((c) => c.id == id);
      if (i != -1) {
        propias[i] = _conEstado(propias[i], Cita.cancelada);
        notifyListeners();
        return;
      }
    }
    _demoCanceladas.add(id);
    notifyListeners();
  }
}
