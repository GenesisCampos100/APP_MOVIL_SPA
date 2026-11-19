import 'package:flutter_test/flutter_test.dart';
import 'package:spa_admin_app/data/models/service_model.dart';

void main() {
  test('ServiceModel convierte la respuesta real de PostgreSQL vía API', () {
    final servicio = ServiceModel.fromJson({
      'id_servicio': 3,
      'id_categoria': 1,
      'categoria': 'Masajes',
      'nombre': 'Masaje con piedras calientes',
      'descripcion': 'Terapia corporal',
      'duracion': 90,
      'precio': '800.00',
      'imagen': null,
      'estado': true,
    });

    expect(servicio.idServicio, '3');
    expect(servicio.idCategoria, '1');
    expect(servicio.precio, 800);
    expect(servicio.duracion, '90 min');
    expect(servicio.estado, true);
  });

  test('El cuerpo para el backend usa los nombres y tipos correctos', () {
    final servicio = ServiceModel(
      idCategoria: '2',
      nombre: 'Masaje relajante',
      descripcion: 'Tratamiento',
      duracion: '60',
      precio: 650.0,
      categoria: 'Masajes',
    );
    final body = servicio.toRequestBody();
    expect(body['id_categoria'], 2);
    expect(body['duracion'], 60);
    expect(body['precio'], 650.0);
    expect(body['nombre'], 'Masaje relajante');
    expect(body.containsKey('id_servicio'), false);
  });

  test('No se permiten categorías o duraciones inválidas', () {
    final servicio = ServiceModel(
      idCategoria: '',
      nombre: 'Masaje',
      duracion: '30',
      precio: 100,
    );
    expect(servicio.toRequestBody, throwsFormatException);
  });
}
