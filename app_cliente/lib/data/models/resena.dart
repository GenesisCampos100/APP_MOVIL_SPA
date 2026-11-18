
import 'convertidores.dart';

/// Reseña de un servicio.
class Resena {
  final int id;
  final int idCita;
  final int calificacionServicio;
  final int calificacionEmpleado;
  final String? comentario;
  final DateTime fecha;

  final String autor;
  final String empleadoNombre;
  final String servicioCategoria;

  // Aspectos seleccionados por el cliente.
  final List<String> aspectos;

  const Resena({
    required this.id,
    required this.idCita,
    required this.calificacionServicio,
    required this.calificacionEmpleado,
    this.comentario,
    required this.fecha,
    this.autor = '',
    this.empleadoNombre = '',
    this.servicioCategoria = '',
    this.aspectos = const [],
  });

  factory Resena.fromJson(Map<String, dynamic> j) => Resena(
        id: aInt(j['id_resena']),
        idCita: aInt(j['id_cita']),
        calificacionServicio: aInt(j['calificacion_ser']),
        calificacionEmpleado: aInt(j['calificacion_emp']),
        comentario: j['comentario'] as String?,
        fecha: aFecha(j['fecha']),
        autor: (j['autor'] ?? '') as String,
        empleadoNombre: (j['empleado_nombre'] ?? '') as String,
        servicioCategoria: (j['servicio_categoria'] ?? '') as String,
        aspectos: (j['aspectos'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
