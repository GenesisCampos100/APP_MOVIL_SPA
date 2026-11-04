import 'convertidores.dart';

/// Servicio de spa. Los campos marcados con la tabla/columna coinciden con
/// la base de datos PostgreSQL (tipo Dart <-> tipo SQL).
class Servicio {
  final int id; //                 servicios.id_servicio   INT
  final int idCategoria; //        servicios.id_categoria  INT (FK)
  final String nombre; //          servicios.nombre        VARCHAR(100)
  final String? descripcion; //    servicios.descripcion   TEXT
  final int minutos; //            servicios.duracion      INT (minutos)
  final double precio; //          servicios.precio        NUMERIC(10,2)
  final String? imagen; //         servicios.imagen        TEXT (URL)
  final bool activo; //            servicios.estado        BOOLEAN

  // Datos que NO son columnas de "servicios":
  final String categoria; //       categorias.nombre (viene de un JOIN)
  final double rating; //          AVG(resenas.calificacion_ser), 0 si no hay
  final bool destacado; //         pendiente: columna nueva o regla de la API

  const Servicio({
    required this.id,
    this.idCategoria = 0,
    required this.nombre,
    this.descripcion,
    required this.minutos,
    required this.precio,
    this.imagen,
    this.activo = true,
    required this.categoria,
    this.rating = 0,
    this.destacado = false,
  });

  /// Crea un Servicio con los nombres de columna de la base de datos.
  factory Servicio.fromJson(Map<String, dynamic> j) => Servicio(
        id: aInt(j['id_servicio']),
        idCategoria: aInt(j['id_categoria']),
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        minutos: aInt(j['duracion']),
        precio: aDouble(j['precio']),
        imagen: j['imagen'] as String?,
        activo: (j['estado'] as bool?) ?? true,
        categoria: (j['categoria'] ?? j['categoria_nombre'] ?? '') as String,
        rating: aDouble(j['rating']),
        destacado: (j['destacado'] as bool?) ?? false,
      );

  String get duracionTexto => minutos == 60 ? '1 hora' : '$minutos min';
  String get precioTexto => '\$${precio.toStringAsFixed(0)}';

  
}
