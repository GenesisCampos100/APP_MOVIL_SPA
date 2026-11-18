
import '../models/resena.dart';
import '../services/api_service.dart';

class ResenasRepository {
  /// GET /api/servicios/:id/resenas
  Future<List<Resena>> obtenerDeServicio(int idServicio) async {
    final data = await ApiService.get(
      '/api/servicios/$idServicio/resenas',
    );

    final List<dynamic> resenasJson = data['resenas'] ?? [];

    return resenasJson.map((json) {
      return Resena.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }
}
