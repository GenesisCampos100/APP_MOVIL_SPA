class ScheduleModel {
  final String idHorario;
  final String idEmpleado;
  final String nombreEmpleado;
  final String puesto;
  final String turno; // 'Turno matutino: 09:00 AM - 03:00 PM', etc.
  final List<String> diasAsignados; // ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
  final String horaInicio;
  final String horaFin;
  final DateTime fecha;
  final bool estado; // true = Activo, false = Inactivo

  ScheduleModel({
    required this.idHorario,
    required this.idEmpleado,
    required this.nombreEmpleado,
    required this.puesto,
    required this.turno,
    required this.diasAsignados,
    required this.horaInicio,
    required this.horaFin,
    required this.fecha,
    this.estado = true,
  });

  ScheduleModel copyWith({
    String? idHorario,
    String? idEmpleado,
    String? nombreEmpleado,
    String? puesto,
    String? turno,
    List<String>? diasAsignados,
    String? horaInicio,
    String? horaFin,
    DateTime? fecha,
    bool? estado,
  }) {
    return ScheduleModel(
      idHorario: idHorario ?? this.idHorario,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
      puesto: puesto ?? this.puesto,
      turno: turno ?? this.turno,
      diasAsignados: diasAsignados ?? this.diasAsignados,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
    );
  }
}
