class AppointmentModel {
  // Campos principales en español de la base de datos (CITAS)
  final String idCita; // id_cita (PK)
  final String idCliente; // id_cliente (FK)
  final String nombreCliente; // Nombre del cliente
  final String nombreServicio; // id_servicio (FK) / Nombre del servicio
  final double precioAplicado; // precio_aplicado
  final String nombreEmpleado; // id_empleado (FK) / Nombre del especialista
  final DateTime fecha; // fecha
  final String horaInicio; // hora_inicio
  final String duracionAplicada; // duracion_aplicada
  final String estado; // estado ('Confirmada', 'Pendiente', 'Completada', 'Cancelada')
  final String? observaciones; // observaciones

  AppointmentModel({
    String? idCita,
    String? id,
    String? idCliente,
    String? clientId,
    String? nombreCliente,
    String? clientName,
    String? nombreServicio,
    String? serviceName,
    double? precioAplicado,
    double? price,
    String? nombreEmpleado,
    String? specialistName,
    DateTime? fecha,
    DateTime? date,
    String? horaInicio,
    String? startTime,
    String? duracionAplicada,
    String? endTime,
    String? estado,
    String? status,
    this.observaciones,
  })  : idCita = idCita ?? id ?? '',
        idCliente = idCliente ?? clientId ?? '',
        nombreCliente = nombreCliente ?? clientName ?? '',
        nombreServicio = nombreServicio ?? serviceName ?? '',
        precioAplicado = precioAplicado ?? price ?? 0.0,
        nombreEmpleado = nombreEmpleado ?? specialistName ?? '',
        fecha = fecha ?? date ?? DateTime.now(),
        horaInicio = horaInicio ?? startTime ?? '',
        duracionAplicada = duracionAplicada ?? endTime ?? '',
        estado = estado ?? status ?? 'Pendiente';

  // Getters alias para compatibilidad
  String get id => idCita;
  String get clientId => idCliente;
  String get clientName => nombreCliente;
  String get serviceName => nombreServicio;
  double get price => precioAplicado;
  String get specialistName => nombreEmpleado;
  DateTime get date => fecha;
  String get startTime => horaInicio;
  String get endTime => duracionAplicada;
  String get status => estado;

  AppointmentModel copyWith({
    String? idCita,
    String? idCliente,
    String? nombreCliente,
    String? nombreServicio,
    double? precioAplicado,
    String? nombreEmpleado,
    DateTime? fecha,
    String? horaInicio,
    String? duracionAplicada,
    String? estado,
    String? observaciones,
  }) {
    return AppointmentModel(
      idCita: idCita ?? this.idCita,
      idCliente: idCliente ?? this.idCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      nombreServicio: nombreServicio ?? this.nombreServicio,
      precioAplicado: precioAplicado ?? this.precioAplicado,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      duracionAplicada: duracionAplicada ?? this.duracionAplicada,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
