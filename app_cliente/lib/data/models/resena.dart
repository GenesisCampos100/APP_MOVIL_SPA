import 'convertidores.dart';

/// Reseña de un servicio. Tipos alineados con la tabla "resenas".
class Resena {
  final int id; //                    resenas.id_resena        INT
  final int idCita; //                resenas.id_cita          INT (FK)
  final int calificacionServicio; //  resenas.calificacion_ser SMALLINT (1 a 5)
  final int calificacionEmpleado; //  resenas.calificacion_emp SMALLINT (1 a 5)
  final String? comentario; //        resenas.comentario       TEXT
  final DateTime fecha; //            resenas.fecha            DATE

  // Datos para mostrar (vienen de JOIN con citas, clientes y empleados):
  final String autor;
  final String empleadoNombre;
  final String servicioCategoria;

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
      );
}
