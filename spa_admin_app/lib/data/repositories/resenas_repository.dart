import 'package:spa_admin_app/data/models/review_model.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Rutas propuestas para el backend compartido: NO existen en el ZIP revisado.
/// No agrega ni modifica rutas, tablas ni permisos de SpaBackend.
class ResenasRepository {
  final ApiClient _client;

  ResenasRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<ReviewsPage> obtenerResenas({
    DateTime? desde,
    DateTime? hasta,
    String? idServicio,
    String? idEmpleado,
    int? estrellas,
    String? buscar,
    int pagina = 1,
  }) async {
    final params = <String, String>{
      'pagina': '$pagina',
      'limite': '20',
      if (desde != null) 'desde': _dia(desde),
      if (hasta != null) 'hasta': _dia(hasta),
      if (idServicio != null && idServicio.isNotEmpty) 'id_servicio': idServicio,
      if (idEmpleado != null && idEmpleado.isNotEmpty) 'id_empleado': idEmpleado,
      if (estrellas != null) 'estrellas': '$estrellas',
      if (buscar != null && buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
    };
    final path = Uri(path: '/admin/resenas', queryParameters: params).toString();
    try {
      return ReviewsPage.fromJson(await _client.get(path));
    } on FormatException catch (e) {
      throw ApiException(message: e.message);
    }
  }

  /// El resumen sigue el contrato de filtros por periodo, servicio y empleado.
  /// Búsqueda y estrellas se aplican SOLO al listado, no al resumen.
  Future<ReviewsSummary> obtenerResumen({
    DateTime? desde,
    DateTime? hasta,
    String? idServicio,
    String? idEmpleado,
  }) async {
    final params = <String, String>{
      if (desde != null) 'desde': _dia(desde),
      if (hasta != null) 'hasta': _dia(hasta),
      if (idServicio != null && idServicio.isNotEmpty) 'id_servicio': idServicio,
      if (idEmpleado != null && idEmpleado.isNotEmpty) 'id_empleado': idEmpleado,
    };
    final path = Uri(path: '/admin/resenas/resumen', queryParameters: params).toString();
    try {
      return ReviewsSummary.fromJson(await _client.get(path));
    } on FormatException catch (e) {
      throw ApiException(message: e.message);
    }
  }

  static String _dia(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
