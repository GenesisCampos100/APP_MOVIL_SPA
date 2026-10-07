import 'convertidores.dart';

/// Cita. Tipos alineados con la tabla "citas".
class Cita {
  static const confirmada = 'Confirmada';
  static const completada = 'Completada';
  static const cancelada = 'Cancelada';

  final int id; //                  citas.id_cita           INT
  final int idCliente; //           citas.id_cliente        INT (FK)
  final int idEmpleado; //          citas.id_empleado       INT (FK)
  final int idServicio; //          citas.id_servicio       INT (FK)
  final DateTime fecha; //          citas.fecha             DATE
  final String horaInicio; //       citas.hora_inicio       TIME ("HH:MM")
  final int duracionAplicada; //    citas.duracion_aplicada INT (minutos)
  final double precioAplicado; //   citas.precio_aplicado   NUMERIC(10,2)
  final String estado; //           citas.estado            VARCHAR(20)
  final String? observaciones; //   citas.observaciones     TEXT

  // Datos para mostrar (vienen de JOIN con servicios y empleados):
  final String servicioNombre;
  final String servicioCategoria;
  final String empleadoNombre;

  const Cita({
    required this.id,
    required this.idCliente,
    required this.idEmpleado,
    required this.idServicio,
    required this.fecha,
    required this.horaInicio,
    required this.duracionAplicada,
    required this.precioAplicado,
    required this.estado,
    this.observaciones,
    this.servicioNombre = '',
    this.servicioCategoria = '',
    this.empleadoNombre = '',
  });

  factory Cita.fromJson(Map<String, dynamic> j) => Cita(
        id: aInt(j['id_cita']),
        idCliente: aInt(j['id_cliente']),
        idEmpleado: aInt(j['id_empleado']),
        idServicio: aInt(j['id_servicio']),
        fecha: aFecha(j['fecha']),
        horaInicio: aHora(j['hora_inicio']),
        duracionAplicada: aInt(j['duracion_aplicada']),
        precioAplicado: aDouble(j['precio_aplicado']),
        estado: j['estado'] as String,
        observaciones: j['observaciones'] as String?,
        servicioNombre: (j['servicio_nombre'] ?? '') as String,
        servicioCategoria: (j['servicio_categoria'] ?? '') as String,
        empleadoNombre: (j['empleado_nombre'] ?? '') as String,
      );

  /// Cita confirmada cuya fecha es hoy o después.
  bool get esProxima {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);
    return estado == confirmada && !fecha.isBefore(hoy);
  }

  /// Datos que la app envía al crear una cita. El cliente sale de la sesión
  /// (token); duración, precio y estado los calcula el servidor.
  static Map<String, dynamic> nueva({
    required int idEmpleado,
    required int idServicio,
    required DateTime fecha,
    required String horaInicio,
    String? observaciones,
  }) =>
      {
        'id_empleado': idEmpleado,
        'id_servicio': idServicio,
        'fecha': aFechaSql(fecha),
        'hora_inicio': horaInicio,
        if (observaciones != null) 'observaciones': observaciones,
      };
}
