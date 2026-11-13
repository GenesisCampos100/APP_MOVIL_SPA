/// Un bloque de trabajo que se repite cada semana.
class BloqueHorario {
  final int idHorario;
  final String diaSemana;
  final String horaInicio;
  final String horaFin;

  const BloqueHorario({
    required this.idHorario,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  factory BloqueHorario.fromJson(Map<String, dynamic> json) => BloqueHorario(
        idHorario: int.tryParse('${json['id_horario']}') ?? 0,
        diaSemana: (json['dia_semana'] ?? '').toString().trim(),
        horaInicio: (json['hora_inicio'] ?? '').toString().trim(),
        horaFin: (json['hora_fin'] ?? '').toString().trim(),
      );

  /// Convierte "09:00:00" en "09:00" para la interfaz.
  String get inicioVisible => _horaVisible(horaInicio);
  String get finVisible => _horaVisible(horaFin);

  static String _horaVisible(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    return '${partes[0]}:${partes[1]}';
  }
}

class EmpleadoConHorarios {
  final int idEmpleado;
  final String nombre;
  final String puesto;
  final bool activo;
  final List<BloqueHorario> horarios;

  const EmpleadoConHorarios({
    required this.idEmpleado,
    required this.nombre,
    required this.puesto,
    required this.activo,
    required this.horarios,
  });

  factory EmpleadoConHorarios.fromJson(Map<String, dynamic> json) {
    final raw = json['horarios'];
    if (raw is! List) {
      throw const FormatException('La información de horarios está incompleta.');
    }
    return EmpleadoConHorarios(
      idEmpleado: int.tryParse('${json['id_empleado']}') ?? 0,
      nombre: (json['nombre'] ?? '').toString().trim(),
      puesto: (json['puesto'] ?? 'Sin puesto asignado').toString(),
      activo: json['activo'] == true,
      horarios: raw.map((elemento) {
        if (elemento is! Map) {
          throw const FormatException('La información de horarios es inválida.');
        }
        return BloqueHorario.fromJson(Map<String, dynamic>.from(elemento));
      }).toList(growable: false),
    );
  }
}
