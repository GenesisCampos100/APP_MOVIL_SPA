import '../../data/models/empleado.dart';
import '../../data/models/servicio.dart';

/// Datos de la reserva que se van juntando pantalla por pantalla.
class ReservaBorrador {
  final Servicio servicio;
  final DateTime fecha;
  final String hora; // "HH:MM"
  final Empleado empleado;

  const ReservaBorrador({
    required this.servicio,
    required this.fecha,
    required this.hora,
    this.empleado = Empleado.cualquiera,
  });

  ReservaBorrador conEmpleado(Empleado e) => ReservaBorrador(
        servicio: servicio,
        fecha: fecha,
        hora: hora,
        empleado: e,
      );
}
