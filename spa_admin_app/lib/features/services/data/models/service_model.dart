class ServiceModel {
  // Campos principales en español de la base de datos (SERVICIOS + CATEGORIAS)
  String idServicio; // id_servicio (PK)
  String? idCategoria; // id_categoria (FK)
  String nombre; // nombre
  String descripcion; // descripcion
  String duracion; // duracion
  double precio; // precio
  String categoria; // nombre de categoría
  bool estado; // estado
  String? imagen; // imagen

  ServiceModel({
    String? idServicio,
    String? id,
    this.idCategoria,
    String? nombre,
    String? name,
    String? descripcion,
    String? description,
    String? duracion,
    String? duration,
    double? precio,
    double? price,
    String? categoria,
    String? category,
    bool? estado,
    bool? isActive,
    this.imagen,
  })  : idServicio = idServicio ?? id ?? '',
        nombre = nombre ?? name ?? '',
        descripcion = descripcion ?? description ?? '',
        duracion = duracion ?? duration ?? '',
        precio = precio ?? price ?? 0.0,
        categoria = categoria ?? category ?? '',
        estado = estado ?? isActive ?? true;

  // Getters alias para compatibilidad
  String get id => idServicio;
  String get name => nombre;
  String get description => descripcion;
  String get duration => duracion;
  String get category => categoria;
  bool get isActive => estado;
}
