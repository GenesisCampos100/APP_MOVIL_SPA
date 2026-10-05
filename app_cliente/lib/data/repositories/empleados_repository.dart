import '../models/empleado.dart';

/// DATOS DE PRUEBA (mock). Con la API sería GET /servicios/:id/empleados,
/// que usa la tabla empleado_servicios (qué empleado realiza qué servicio).
class EmpleadosRepository {
  Future<List<Empleado>> obtenerParaServicio(int idServicio) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mock;
  }

  static const _mock = [
    Empleado(id: 1, nombre: 'Zinedine', apellidoP: 'Miranda', puesto: 'Masajista corporal', rating: 4.5),
    Empleado(id: 2, nombre: 'Vanessa', apellidoP: 'Sibaja', puesto: 'Aromaterapia y relajación', rating: 4.8),
    Empleado(id: 3, nombre: 'Mario', apellidoP: 'Ballato', puesto: '6 años de experiencia', rating: 4.8),
  ];
}
