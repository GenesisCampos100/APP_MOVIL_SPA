import 'convertidores.dart';

/// Empleado / especialista. Tipos alineados con la tabla "empleados".
class Empleado {
  final int id; //              empleados.id_empleado  INT
  final String nombre; //       empleados.nombre       VARCHAR(100)
  final String apellidoP; //    empleados.apellido_p   VARCHAR(100)
  final String? apellidoM; //   empleados.apellido_m   VARCHAR(100)
  final String puesto; //       puestos.nombre (JOIN)
  final String? foto; //        usuarios.foto (JOIN)
  final double rating; //       AVG(resenas.calificacion_emp)

  const Empleado({
    required this.id,
    required this.nombre,
    this.apellidoP = '',
    this.apellidoM,
    this.puesto = '',
    this.foto,
    this.rating = 0,
  });

  /// Opción "Cualquier disponible": el sistema asigna al primero libre.
  static const Empleado cualquiera = Empleado(id: 0, nombre: 'Cualquier disponible');
  bool get esCualquiera => id == 0;

  factory Empleado.fromJson(Map<String, dynamic> j) => Empleado(
        id: aInt(j['id_empleado']),
        nombre: j['nombre'] as String,
        apellidoP: (j['apellido_p'] ?? '') as String,
        apellidoM: j['apellido_m'] as String?,
        puesto: (j['puesto'] ?? j['puesto_nombre'] ?? '') as String,
        foto: j['foto'] as String?,
        rating: aDouble(j['rating']),
      );

  String get nombreCompleto => [nombre, apellidoP, apellidoM]
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .join(' ');

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
}
