import 'dart:typed_data';

import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_endpoints.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Única fuente de datos del módulo Gestión de Servicios.
/// No escribe directamente en PostgreSQL: usa SpaBackend de Vanessa.
class ServiciosRepository {
  final ApiClient _client;

  ServiciosRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<ServiceModel>> obtenerServicios() async {
    final respuesta = await _client.get(ApiEndpoints.services);
    return _parsearLista(respuesta);
  }

  /// Catálogo completo, disponible únicamente para el Administrador.
  Future<List<ServiceModel>> obtenerTodosServiciosAdmin() async {
    final respuesta = await _client.get(ApiEndpoints.adminServices);
    return _parsearLista(respuesta);
  }

  List<ServiceModel> _parsearLista(dynamic respuesta) {
    if (respuesta is! List) {
      throw ApiException(message: 'La API no devolvió una lista de servicios.');
    }
    final servicios = <ServiceModel>[];
    for (final dato in respuesta) {
      if (dato is! Map) {
        throw ApiException(message: 'Un servicio tiene un formato no válido.');
      }
      final servicio = ServiceModel.fromJson(Map<String, dynamic>.from(dato));
      if (servicio.idServicio.isEmpty || servicio.nombre.isEmpty) {
        throw ApiException(message: 'La API devolvió un servicio incompleto.');
      }
      servicios.add(servicio);
    }
    return servicios;
  }

  /// Catálogo real, incluyendo categorías que todavía no tienen servicios.
  Future<Map<String, String>> obtenerCategorias() async {
    final respuesta = await _client.get('/admin/servicios/categorias');
    if (respuesta is! List) {
      throw ApiException(message: 'La API no devolvió la lista de categorías.');
    }
    final categorias = <String, String>{};
    for (final dato in respuesta) {
      if (dato is! Map) {
        throw ApiException(message: 'La API devolvió una categoría inválida.');
      }
      final id = int.tryParse('${dato['id_categoria']}');
      final nombre = dato['nombre']?.toString().trim() ?? '';
      if (id == null || id <= 0 || nombre.isEmpty) {
        throw ApiException(message: 'La API devolvió una categoría incompleta.');
      }
      categorias['$id'] = nombre;
    }
    return categorias;
  }

  Future<MapEntry<String, String>> crearCategoria(String nombre) async {
    final respuesta = await _client.post('/admin/servicios/categorias',
        body: {'nombre': nombre.trim()});
    if (respuesta is! Map) {
      throw ApiException(message: 'La API no confirmó la categoría.');
    }
    final id = int.tryParse('${respuesta['id_categoria']}');
    final etiqueta = respuesta['nombre']?.toString().trim() ?? '';
    if (id == null || id <= 0 || etiqueta.isEmpty) {
      throw ApiException(message: 'La API devolvió una categoría incompleta.');
    }
    return MapEntry('$id', etiqueta);
  }

  /// Reactiva mediante PUT /api/servicios/:id, existente en el backend.
  /// No se altera la operación de catálogo de la pestaña inferior.
  Future<void> reactivarServicio(ServiceModel servicio) async {
    if (int.tryParse(servicio.idServicio) == null) {
      throw const FormatException('El identificador del servicio no es válido.');
    }
    final reactivado = ServiceModel(
      idServicio: servicio.idServicio,
      idCategoria: servicio.idCategoria,
      nombre: servicio.nombre,
      descripcion: servicio.descripcion,
      duracion: servicio.duracion,
      precio: servicio.precio,
      categoria: servicio.categoria,
      estado: true,
      imagen: servicio.imagen,
    );
    await actualizarServicio(reactivado);
  }

  /// Sube el archivo y recibe la ruta pública relativa que se guarda en servicios.imagen.
  Future<String> subirImagen(Uint8List bytes, {required String mimeType}) async {
    if (bytes.isEmpty || bytes.lengthInBytes > 3 * 1024 * 1024) {
      throw const FormatException('La imagen debe pesar menos de 3 MB.');
    }
    final respuesta = await _client.postImagen(
      '/admin/servicios/imagen', bytes: bytes, mimeType: mimeType,
    );
    if (respuesta is! Map || respuesta['imagen'] is! String) {
      throw ApiException(message: 'La API no devolvió una ruta válida de la fotografía.');
    }
    final ruta = (respuesta['imagen'] as String).trim();

  final rutaAnterior = RegExp(
    r'^/uploads/servicios/[a-zA-Z0-9-]+\.(jpg|png|webp)$',
  ).hasMatch(ruta);

  final uri = Uri.tryParse(ruta);

  final urlSupabase = uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'qpflbdklyxrmkoobaddm.supabase.co' &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      RegExp(
        r'^/storage/v1/object/public/servicios/[a-zA-Z0-9-]+\.(jpg|png|webp)$',
      ).hasMatch(uri.path);

  if (!rutaAnterior && !urlSupabase) {
    throw ApiException(
      message: 'La API devolvió una ubicación inesperada.',
    );
  }

    return ruta;
  }

  Future<void> crearServicio(ServiceModel servicio) async {
    await _client.post(ApiEndpoints.services, body: servicio.toRequestBody());
  }

  Future<void> actualizarServicio(ServiceModel servicio) async {
    if (int.tryParse(servicio.idServicio) == null) {
      throw const FormatException('El identificador del servicio no es válido.');
    }
    await _client.put(
      ApiEndpoints.serviceById(servicio.idServicio),
      body: servicio.toRequestBody(),
    );
  }

  Future<void> desactivarServicio(ServiceModel servicio) async {
    if (int.tryParse(servicio.idServicio) == null) {
      throw const FormatException('El identificador del servicio no es válido.');
    }
    await _client.delete(ApiEndpoints.serviceById(servicio.idServicio));
  }
}
