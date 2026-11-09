
import '../../data/models/empleado.dart';
import '../../data/models/servicio.dart';

/// Datos de la reserva que se van juntando pantalla por pantalla.
class ReservaBorrador {
  final Servicio servicio;
  final DateTime fecha;
  final String hora;
  final Empleado empleado;

  // Datos del apartado temporal creado en el backend.
  final int? idReserva;
  final DateTime? fechaExpiracion;

  const ReservaBorrador({
    required this.servicio,
    required this.fecha,
    required this.hora,
    this.empleado = Empleado.cualquiera,
    this.idReserva,
    this.fechaExpiracion,
  });

  ReservaBorrador conEmpleado(Empleado e) => ReservaBorrador(
        servicio: servicio,
        fecha: fecha,
        hora: hora,
        empleado: e,
        idReserva: idReserva,
        fechaExpiracion: fechaExpiracion,
      );

  /// Actualiza el borrador con el apartado creado por el backend.
  ReservaBorrador conApartado({
    required int idReserva,
    required DateTime fechaExpiracion,
    required Empleado empleado,
  }) {
    return ReservaBorrador(
      servicio: servicio,
      fecha: fecha,
      hora: hora,
      empleado: empleado,
      idReserva: idReserva,
      fechaExpiracion: fechaExpiracion,
    );
  }
}
