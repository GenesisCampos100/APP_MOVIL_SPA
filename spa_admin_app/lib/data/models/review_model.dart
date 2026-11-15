/// Contrato de solo lectura para las reseñas reales entregadas por SpaBackend.
/// No se crean puntuaciones ni identificadores ficticios en la aplicación.
class ReviewModel {
  final String id;
  final String? cliente;
  final String? comentario;
  final DateTime? fecha;
  final String? servicioId;
  final String? servicioNombre;
  final String? empleadoId;
  final String? empleadoNombre;
  final int? estrellasServicio;
  final int? estrellasTerapeuta;
  final List<String> aspectosDestacados;

  const ReviewModel({
    required this.id,
    this.cliente,
    this.comentario,
    this.fecha,
    this.servicioId,
    this.servicioNombre,
    this.empleadoId,
    this.empleadoNombre,
    this.estrellasServicio,
    this.estrellasTerapeuta,
    this.aspectosDestacados = const [],
  });

  static String? _texto(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? _estrellas(dynamic value) {
    final n = int.tryParse(value?.toString() ?? '');
    return n != null && n >= 1 && n <= 5 ? n : null;
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final id = _texto(json['id_resena']);
    if (id == null) {
      throw const FormatException('La reseña no contiene identificador.');
    }

    final serv = json['servicio'];
    final emp = json['empleado'];
    final servicio = serv is Map ? Map<String, dynamic>.from(serv) : <String, dynamic>{};
    final empleado = emp is Map ? Map<String, dynamic>.from(emp) : <String, dynamic>{};
    final aspectos = json['aspectos_destacados'];

    return ReviewModel(
      id: id,
      cliente: _texto(json['cliente']),
      comentario: _texto(json['comentario']),
      fecha: DateTime.tryParse(_texto(json['fecha_creacion']) ?? '')?.toLocal(),
      servicioId: _texto(servicio['id_servicio']),
      servicioNombre: _texto(servicio['nombre']),
      empleadoId: _texto(empleado['id_empleado']),
      empleadoNombre: _texto(empleado['nombre']),
      estrellasServicio: _estrellas(json['estrellas_servicio']),
      estrellasTerapeuta: _estrellas(json['estrellas_terapeuta']),
      aspectosDestacados: aspectos is List
          ? aspectos.whereType<String>().where((s) => s.trim().isNotEmpty).toList(growable: false)
          : const [],
    );
  }
}

class ReviewsPage {
  final List<ReviewModel> resenas;
  final int pagina;
  final int totalPaginas;
  final int total;

  const ReviewsPage({
    required this.resenas,
    required this.pagina,
    required this.totalPaginas,
    required this.total,
  });

  static int _entero(dynamic valor, int defecto) =>
      int.tryParse(valor?.toString() ?? '') ?? defecto;

  factory ReviewsPage.fromJson(dynamic data) {
    if (data is! Map || data['resenas'] is! List || data['paginacion'] is! Map) {
      throw const FormatException('Formato de lista de reseñas no válido.');
    }
    final page = Map<String, dynamic>.from(data);
    final meta = Map<String, dynamic>.from(page['paginacion'] as Map);
    final filas = (page['resenas'] as List).map((row) {
      if (row is! Map) throw const FormatException('Reseña no válida.');
      return ReviewModel.fromJson(Map<String, dynamic>.from(row));
    }).toList(growable: false);
    return ReviewsPage(
      resenas: filas,
      pagina: _entero(meta['pagina'], 1),
      totalPaginas: _entero(meta['total_paginas'], 1),
      total: _entero(meta['total'], filas.length),
    );
  }
}

class ReviewsSummary {
  final int total;
  final double? promedioServicios;
  final double? promedioTerapeutas;
  final Map<int, int> distribucionServicios;

  const ReviewsSummary({
    required this.total,
    required this.promedioServicios,
    required this.promedioTerapeutas,
    required this.distribucionServicios,
  });

  factory ReviewsSummary.fromJson(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Formato del resumen de reseñas no válido.');
    }
    final resumen = Map<String, dynamic>.from(data);
    final raw = resumen['distribucion_servicios'];
    final counts = <int, int>{};
    if (raw is Map) {
      for (var rating = 1; rating <= 5; rating++) {
        final count = int.tryParse(raw['$rating']?.toString() ?? '');
        counts[rating] = count != null && count >= 0 ? count : 0;
      }
    }
    double? number(dynamic value) {
      final n = double.tryParse(value?.toString() ?? '');
      return n != null && n.isFinite && n >= 0 && n <= 5 ? n : null;
    }
    final total = int.tryParse(resumen['total']?.toString() ?? '');
    if (total == null || total < 0) {
      throw const FormatException('Total de reseñas no válido.');
    }
    return ReviewsSummary(
      total: total,
      promedioServicios: number(resumen['promedio_servicios']),
      promedioTerapeutas: number(resumen['promedio_terapeutas']),
      distribucionServicios: counts,
    );
  }
}
