/// Modelo compartido del catálogo de servicios de Aura SPA.
/// Conserva los nombres originales para las vistas de asignaciones existentes.
class ServiceModel {
  String idServicio;
  String? idCategoria;
  String nombre;
  String descripcion;
  String duracion;
  double precio;
  String categoria;
  bool estado;
  String? imagen;

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

  /// Contrato real del GET /api/servicios del backend de Vanessa.
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      idServicio: '${json['id_servicio'] ?? ''}',
      idCategoria: json['id_categoria']?.toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      duracion: '${json['duracion'] ?? ''} min',
      precio: double.tryParse('${json['precio'] ?? ''}') ?? 0,
      categoria: (json['categoria'] ?? '').toString(),
      estado: json['estado'] == true,
      imagen: json['imagen']?.toString(),
    );
  }

  /// Datos requeridos para POST y PUT /api/servicios.
  /// El ID lo asigna PostgreSQL al crear; no se inventa en Flutter.
  Map<String, dynamic> toRequestBody() {
    final categoriaNumero = int.tryParse(idCategoria ?? '');
    final coincidencia = RegExp(r'^\d+').firstMatch(duracion.trim());
    final duracionNumero = coincidencia == null
        ? null
        : int.tryParse(coincidencia.group(0)!);

    if (categoriaNumero == null || categoriaNumero <= 0) {
      throw const FormatException('Selecciona una categoría válida.');
    }
    if (nombre.trim().isEmpty) {
      throw const FormatException('El nombre del servicio es obligatorio.');
    }
    if (duracionNumero == null || duracionNumero <= 0) {
      throw const FormatException('La duración debe ser mayor que cero.');
    }
    if (!precio.isFinite || precio < 0) {
      throw const FormatException('Introduce un precio válido.');
    }

    return {
      'id_categoria': categoriaNumero,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'duracion': duracionNumero,
      'precio': precio,
      'imagen': imagen,
      'estado': estado,
    };
  }

  // Getters de compatibilidad con las vistas existentes.
  String get id => idServicio;
  String get name => nombre;
  String get description => descripcion;
  String get duration => duracion;
  String get category => categoria;
  bool get isActive => estado;
}
