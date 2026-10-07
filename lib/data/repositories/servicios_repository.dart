import '../models/servicio.dart';

/// Hoy devuelve datos de prueba (mock). Cuando Vanessa tenga GET /servicios,
/// solo se cambia el contenido de obtenerServicios(); las pantallas no cambian.
class ServiciosRepository {
  static const categorias = [
    'Corporal',
    'Facial',
    'Manicure',
    'Aromaterapia',
    'Pedicure',
  ];

  Future<List<Servicio>> obtenerServicios() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mock;
  }

  static const _mock = [
    Servicio(id: 1, nombre: 'Masaje relajante', categoria: 'Corporal', precio: 500, minutos: 45, rating: 4.5, destacado: true),
    Servicio(id: 2, nombre: 'Facial hidratante', categoria: 'Facial', precio: 900, minutos: 45, rating: 4.5, destacado: true),
    Servicio(id: 3, nombre: 'Manicure clásica', categoria: 'Manicure', precio: 500, minutos: 45, rating: 4.5),
    Servicio(id: 4, nombre: 'Ritual de relajación', categoria: 'Aromaterapia', precio: 800, minutos: 60, rating: 4.6),
    Servicio(id: 5, nombre: 'Pedicure Spa', categoria: 'Pedicure', precio: 600, minutos: 50, rating: 4.8),
  ];
}
