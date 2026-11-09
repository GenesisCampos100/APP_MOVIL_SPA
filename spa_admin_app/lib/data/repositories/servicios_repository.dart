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
